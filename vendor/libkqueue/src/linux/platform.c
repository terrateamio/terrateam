/*
 * Copyright (c) 2011 Mark Heily <mark@heily.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

# define _GNU_SOURCE
# include <poll.h>
#include <sys/types.h>
#include <sys/resource.h>
#include "../common/private.h"


//XXX-FIXME TEMP
const struct filter evfilt_proc = EVFILT_NOTIMPL;

/*
 * Per-thread epoll event buffer used to ferry data between
 * kevent_wait() and kevent_copyout().
 */
static __thread struct epoll_event epevt[MAX_KEVENT];

extern pthread_mutex_t kq_mtx;
/*
 * Monitoring thread that takes care of cleaning up kqueues (on linux only)
 */
static pthread_t monitoring_thread;
static pid_t monitoring_tid; /* Monitoring thread */
pthread_once_t monitoring_thread_initialized = PTHREAD_ONCE_INIT;
pthread_cond_t monitoring_thread_cond = PTHREAD_COND_INITIALIZER;

/*
 * Number of active kqueues.
 * When the last kqueue is closed, the monitoring thread can be stopped.
 */
static unsigned int kqueue_cnt = 0;

/*
 * Map for kqueue pipes where index is the read side (for which signals are received)
 * and value is the write side that gets closed and corresponds to the kqueue id.
 */
static unsigned int *fd_map;

/*
 * Map kqueue id to counter for kq cleanups.
 * When cleanup counter is at 0, cleanup can be performed by signal handler.
 * Otherwise, it means cleanup was already performed for this FD in linux_kqueue_free.
 */
static unsigned int *fd_cleanup_cnt;

const struct kqueue_vtable kqops = {
    .kqueue_init        = linux_kqueue_init,
    .kqueue_free        = linux_kqueue_free,
    .kevent_wait        = linux_kevent_wait,
    .kevent_copyout     = linux_kevent_copyout,
    .eventfd_init       = linux_eventfd_init,
    .eventfd_close      = linux_eventfd_close,
    .eventfd_raise      = linux_eventfd_raise,
    .eventfd_lower      = linux_eventfd_lower,
    .eventfd_descriptor = linux_eventfd_descriptor,
};

static bool
linux_kqueue_cleanup(struct kqueue *kq);

unsigned int get_fd_limit(void);
/*
 * Monitoring thread that loops on waiting for signals to be received
 */
static void *
monitoring_thread_start(void *arg)
{
    short end_thread = 0;
    int res = 0;
    siginfo_t info;
    int fd;
    int nb_max_fd;
    struct kqueue *kq;
    sigset_t monitoring_sig_set;

    nb_max_fd = get_fd_limit();

    sigemptyset(&monitoring_sig_set);
    sigfillset(&monitoring_sig_set);

    pthread_sigmask(SIG_BLOCK, &monitoring_sig_set, NULL);

    sigemptyset(&monitoring_sig_set);
    sigaddset(&monitoring_sig_set, SIGRTMIN + 1);

    (void) pthread_mutex_lock(&kq_mtx);

    monitoring_tid = syscall(SYS_gettid);

    fd_map = calloc(nb_max_fd, sizeof(unsigned int));
    if (fd_map == NULL) {
    error:
        (void) pthread_mutex_unlock(&kq_mtx);
        return NULL;
    }

    fd_cleanup_cnt = calloc(nb_max_fd, sizeof(unsigned int));
    if (fd_cleanup_cnt == NULL){
        free(fd_map);
        goto error;
    }

    /*
     * Now that thread is initialized, let kqueue init resume
     */
    pthread_cond_broadcast(&monitoring_thread_cond);
    (void) pthread_mutex_unlock(&kq_mtx);

    pthread_detach(pthread_self());

    while (!end_thread) {
        /*
         * Wait for signal notifying us that a change has occured on the pipe
         * It's not possible to only listen on FD close but no other operation
         * should be performed on the kqueue.
         */
        res = sigwaitinfo(&monitoring_sig_set, &info);
        if( res != -1 ) {
            (void) pthread_mutex_lock(&kq_mtx);
            /*
             * Signal is received for read side of pipe
             * Get FD for write side as it's the kqueue identifier
             */
            fd = fd_map[info.si_fd];
            if (fd) {
                kq = kqueue_lookup(fd);
                if (kq) {
                    /* If kqueue instance for this FD hasn't been cleaned yet */
                    if (fd_cleanup_cnt[kq->kq_id] == 0) {
                        linux_kqueue_cleanup(kq);
                    }

                    /* Decrement cleanup counter as signal handler has been run for this FD */
                    fd_cleanup_cnt[kq->kq_id]--;
                } else {
                    /* Should not happen */
                    dbg_puts("Failed to lookup FD");
                }
            } else {
                /* Should not happen */
                dbg_puts("Got signal from unknown FD");
            }

            /*
             * Stop thread if all kqueues have been closed
             */
            if (kqueue_cnt == 0) {
                end_thread = 1;

                /* Reset so that thread can be restarted */
                monitoring_thread_initialized = PTHREAD_ONCE_INIT;

                /* Free thread resources */
                free(fd_map);
                free(fd_cleanup_cnt);
            }

            (void) pthread_mutex_unlock(&kq_mtx);
        } else {
            dbg_perror("sigwait()");
        }
    }

    return NULL;
}

static void
linux_kqueue_start_thread()
{
    if (pthread_create(&monitoring_thread, NULL, &monitoring_thread_start, NULL)) {
         dbg_perror("linux_kqueue_start_thread failure");
    }

    /* Wait for thread creating to be done as we need monitoring_tid to be available */
    pthread_cond_wait(&monitoring_thread_cond, &kq_mtx);
}

int
linux_kqueue_init(struct kqueue *kq)
{
    struct f_owner_ex sig_owner;

    kq->epollfd = epoll_create(1);
    if (kq->epollfd < 0) {
        dbg_perror("epoll_create(2)");
        return (-1);
    }

    /*
     * The standard behaviour when closing a kqueue fd is for the underlying resources to be freed.
     * In order to catch the close on the libkqueue fd, we use a pipe and return the write end as kq_id.
     * Closing the end will cause the pipe to be close which will be caught by the monitoring thread.
     */
    if (pipe(kq->pipefd)) {
        close(kq->epollfd);
        return (-1);
    }

    if (filter_register_all(kq) < 0) {
        error:
        close(kq->epollfd);
        close(kq->pipefd[0]);
        close(kq->pipefd[1]);
        return (-1);
    }

    kq->kq_id = kq->pipefd[1];

    if (fcntl(kq->pipefd[0], F_SETFL, fcntl(kq->pipefd[0], F_GETFL, 0) | O_ASYNC) < 0) {
        dbg_perror("failed setting O_ASYNC");
        goto error;
    }

    if (fcntl(kq->pipefd[0], F_SETSIG, SIGRTMIN + 1) < 0) {
        dbg_perror("failed settting F_SETSIG");
        goto error;
    }

    (void) pthread_mutex_lock(&kq_mtx);

    /* Start monitoring thread during first initialization */
    (void) pthread_once(&monitoring_thread_initialized, linux_kqueue_start_thread);

    /* Update pipe FD map */
    fd_map[kq->pipefd[0]] = kq->pipefd[1];

    /* Increment kqueue counter */
    kqueue_cnt++;

    sig_owner.type = F_OWNER_TID;
    sig_owner.pid = monitoring_tid;
    if (fcntl(kq->pipefd[0], F_SETOWN_EX, &sig_owner) < 0) {
        dbg_perror("failed settting F_SETOWN");
        (void) pthread_mutex_unlock(&kq_mtx);
        goto error;
    }

    (void) pthread_mutex_unlock(&kq_mtx);

 #if DEADWOOD
    //might be useful in posix

    /* Add each filter's pollable descriptor to the epollset */
    for (i = 0; i < EVFILT_SYSCOUNT; i++) {
        filt = &kq->kq_filt[i];

        if (filt->kf_id == 0)
            continue;

        memset(&ev, 0, sizeof(ev));
        ev.events = EPOLLIN;
        ev.data.ptr = filt;

        if (epoll_ctl(kq->kq_id, EPOLL_CTL_ADD, filt->kf_pfd, &ev) < 0) {
            dbg_perror("epoll_ctl(2)");
            close(kq->kq_id);
            return (-1);
        }
    }
#endif

    return (0);
}

/*
 * Cleanup kqueue resources
 * Should be done while holding kq_mtx
 * return
 * - true if epoll fd and pipes were closed
 * - false if epoll fd was already closed
 */
static bool
linux_kqueue_cleanup(struct kqueue *kq)
{
    char buffer;
    ssize_t ret;
    int pipefd;

    filter_unregister_all(kq);
    if (kq->epollfd > 0) {
        close(kq->epollfd);
        kq->epollfd = -1;
    } else {
        // Don't do cleanup if epollfd has already been closed
        return false;
    }

    /*
     * read will return 0 on pipe EOF (i.e. if the write end of the pipe has been closed)
     */
    ret = read(kq->pipefd[0], &buffer, 1);
    if (ret == -1 && errno == EWOULDBLOCK) {
        // Shoudn't happen unless kqops.kqueue_free is called on an open FD
        dbg_puts("kqueue wasn't closed");
        close(kq->pipefd[1]);
        kq->pipefd[1] = -1;
    } else if (ret > 0) {
        // Shouldn't happen unless data is written to kqueue FD
        // Ignore write and continue with close
        dbg_puts("Unexpected data available on kqueue FD");
    }

    pipefd = kq->pipefd[0];
    if (pipefd > 0) {
        close(pipefd);
        kq->pipefd[0] = -1;
    }

    fd_map[pipefd] = 0;

    /* Decrement kqueue counter */
    kqueue_cnt--;

    return true;
}

void
linux_kqueue_free(struct kqueue *kq)
{
    /* Increment cleanup counter as cleanup is being performed outside signal handler */
    if (linux_kqueue_cleanup(kq))
        fd_cleanup_cnt[kq->kq_id]++;
    else /* Reset counter as FD had already been cleaned */
        fd_cleanup_cnt[kq->kq_id] = 0;

    free(kq);
}

static int
linux_kevent_wait_hires(
        struct kqueue *kq,
        const struct timespec *timeout)
{
    int n;
#if HAVE_DECL_PPOLL
    struct pollfd fds;

    dbg_printf("waiting for events (timeout=%ld sec %ld nsec)",
            timeout->tv_sec, timeout->tv_nsec);
    fds.fd = kqueue_epfd(kq);
    fds.events = POLLIN;

    n = ppoll(&fds, 1, timeout, NULL);
#else
    int epfd;
    fd_set fds;

    dbg_printf("waiting for events (timeout=%ld sec %ld nsec)",
            timeout->tv_sec, timeout->tv_nsec);

    epfd = kqueue_epfd(kq);
    FD_ZERO(&fds);
    FD_SET(epfd, &fds);
    n = pselect(epfd + 1, &fds, NULL , NULL, timeout, NULL);
#endif

    if (n < 0) {
        if (errno == EINTR) {
            dbg_puts("signal caught");
            return (-1);
        }
        dbg_perror("ppoll(2) or pselect(2)");
        return (-1);
    }
    return (n);
}

int
linux_kevent_wait(
        struct kqueue *kq,
        int nevents,
        const struct timespec *ts)
{
    int timeout, nret;

    /* Use a high-resolution syscall if the timeout value's tv_nsec value has a resolution
     * finer than a millisecond. */
    if (ts != NULL && (ts->tv_nsec % 1000000 != 0)) {
        nret = linux_kevent_wait_hires(kq, ts);
        if (nret <= 0)
            return (nret);

        /* epoll_wait() should have ready events */
        timeout = 0;
    } else {
        /* Convert timeout to the format used by epoll_wait() */
        if (ts == NULL)
            timeout = -1;
        else
            timeout = (1000 * ts->tv_sec) + (ts->tv_nsec / 1000000);
    }

    dbg_puts("waiting for events");
    nret = epoll_wait(kqueue_epfd(kq), &epevt[0], nevents, timeout);
    if (nret < 0) {
        dbg_perror("epoll_wait");
        return (-1);
    }

    return (nret);
}

int
linux_kevent_copyout(struct kqueue *kq, int nready,
        struct kevent *eventlist, int nevents UNUSED)
{
    struct epoll_event *ev;
    struct filter *filt;
    struct knote *kn;
    int i, nret, rv;

    nret = nready;
    for (i = 0; i < nready; i++) {
        ev = &epevt[i];
        kn = (struct knote *) ev->data.ptr;
        filt = &kq->kq_filt[~(kn->kev.filter)];
        rv = filt->kf_copyout(eventlist, kn, ev);
        if (unlikely(rv < 0)) {
            dbg_puts("knote_copyout failed");
            /* XXX-FIXME: hard to handle this without losing events */
            abort();
        }

        /*
         * Certain flags cause the associated knote to be deleted
         * or disabled.
         */
        if (eventlist->flags & EV_DISPATCH)
            knote_disable(filt, kn); //FIXME: Error checking
        if (eventlist->flags & EV_ONESHOT) {
            knote_delete(filt, kn); //FIXME: Error checking
        }

        /* If an empty kevent structure is returned, the event is discarded. */
        /* TODO: add these semantics to windows + solaris platform.c */
        if (likely(eventlist->filter != 0)) {
            eventlist++;
        } else {
            dbg_puts("spurious wakeup, discarding event");
            nret--;
        }
    }

    return (nret);
}

int
linux_eventfd_init(struct eventfd *e)
{
    int evfd;

    evfd = eventfd(0, 0);
    if (evfd < 0) {
        dbg_perror("eventfd");
        return (-1);
    }
    if (fcntl(evfd, F_SETFL, O_NONBLOCK) < 0) {
        dbg_perror("fcntl");
        close(evfd);
        return (-1);
    }
    e->ef_id = evfd;

    return (0);
}

void
linux_eventfd_close(struct eventfd *e)
{
    close(e->ef_id);
    e->ef_id = -1;
}

int
linux_eventfd_raise(struct eventfd *e)
{
    uint64_t counter;
    int rv = 0;

    dbg_puts("raising event level");
    counter = 1;
    if (write(e->ef_id, &counter, sizeof(counter)) < 0) {
        switch (errno) {
            case EAGAIN:
                /* Not considered an error */
                break;

            case EINTR:
                rv = -EINTR;
                break;

            default:
                dbg_printf("write(2): %s", strerror(errno));
                rv = -1;
        }
    }
    return (rv);
}

int
linux_eventfd_lower(struct eventfd *e)
{
    uint64_t cur;
    ssize_t n;
    int rv = 0;

    /* Reset the counter */
    dbg_puts("lowering event level");
    n = read(e->ef_id, &cur, sizeof(cur));
    if (n < 0) {
        switch (errno) {
            case EAGAIN:
                /* Not considered an error */
                break;

            case EINTR:
                rv = -EINTR;
                break;

            default:
                dbg_printf("read(2): %s", strerror(errno));
                rv = -1;
        }
    } else if (n != sizeof(cur)) {
        dbg_puts("short read");
        rv = -1;
    }

    return (rv);
}

int
linux_eventfd_descriptor(struct eventfd *e)
{
    return (e->ef_id);
}

/** Determine what type of file descriptor the knote describes
 *
 * Sets the kn_flags field of the knote to one of:
 * - KNFL_FILE               FD is a regular file.
 * - KNFL_PIPE               FD is one end of a pipe.
 * - KNFL_BLK                FD is a block device.
 * - KNFL_CHR                FD is a character device.
 * - KNFL_SOCKET_STREAM      FD is a streaming socket(reliable connection-oriented byte streams).
 * - KNFL_SOCKET_DGRAM       FD is a datagram socket (unreliable connectionless messages).
 * - KNFL_SOCKET_RDM         FD is a reliable datagram socket (reliable connectionless messages).
 * - KNFL_SOCKET_SEQPACKET   FD is a sequenced packet socket (reliable connection-oriented messages).
 * - KNFL_SOCKET_RAW         FD is a raw socket as documented in raw(7).
 *
 * Additionally KNFL_SOCKET_* types may have the KNFL_SOCKET_PASSIVE flag set if they
 * are never expected to return data, but only provide an indication of whether data is available.
 *
 * We currently check whether the socket is a 'listening' socket (SO_ACCEPTCONN) or has a BPF rule
 * attached (SO_GET_FILTER) to determine if it's passive.
 *
 * @param[in] kn    holding the file descriptor.
 * @return
 *    - 0 on success.
 *    - -1 on failure.
 */
int
linux_get_descriptor_type(struct knote *kn)
{
    socklen_t slen;
    struct stat sb;
    int ret, lsock, stype;
    const int fd = (int)kn->kev.ident;

    /*
     * Determine the actual descriptor type.
     */
    if (fstat(fd, &sb) < 0) {
        dbg_perror("fstat(2)");
        return (-1);
    }

    switch (sb.st_mode & S_IFMT) {
        default:
            errno = EBADF;
            dbg_perror("unknown fd type");
            return (-1);

        case S_IFREG:
            dbg_printf("fd %d is a regular file\n", fd);
            kn->kn_flags |= KNFL_FILE;
            return (0);

        case S_IFIFO:
            dbg_printf("fd %d is a pipe\n", fd);
            kn->kn_flags |= KNFL_PIPE;
            return (0);

        case S_IFBLK:
            dbg_printf("fd %d is a block device\n", fd);
            kn->kn_flags |= KNFL_BLOCKDEV;
            return (0);

        case S_IFCHR:
            dbg_printf("fd %d is a character device\n", fd);
            kn->kn_flags |= KNFL_CHARDEV;
            return (0);

        case S_IFSOCK:
            dbg_printf("fd %d is a socket\n", fd);
            break; /* deferred type determination */
    }

    /*
     * Determine socket type.
     */
    slen = sizeof(stype);
    stype = 0;
    ret = getsockopt(fd, SOL_SOCKET, SO_TYPE, &stype, &slen);
    if (ret < 0) {
        dbg_perror("getsockopt(3)");
        return (-1);
    }
    switch (stype) {
        case SOCK_STREAM:
            dbg_printf("fd %d is a stream socket\n", fd);
            kn->kn_flags |= KNFL_SOCKET_STREAM;
            break;

        case SOCK_DGRAM:
            dbg_printf("fd %d is a datagram socket\n", fd);
            kn->kn_flags |= KNFL_SOCKET_DGRAM;
            break;

        case SOCK_RDM:
            dbg_printf("fd %d is a reliable datagram socket\n", fd);
            kn->kn_flags |= KNFL_SOCKET_RDM;
            break;

        case SOCK_SEQPACKET:
            dbg_printf("fd %d is a sequenced and reliable datagram socket\n", fd);
            kn->kn_flags |= KNFL_SOCKET_SEQPACKET;
            break;

        case SOCK_RAW:
            dbg_printf("fd %d is a raw socket\n", fd);
            kn->kn_flags |= KNFL_SOCKET_RAW;
            break;

        default:
            errno = EBADF;
            dbg_perror("unknown socket type");
            return (-1);
    }

    slen = sizeof(lsock);
    lsock = 0;
    ret = getsockopt(fd, SOL_SOCKET, SO_ACCEPTCONN, &lsock, &slen);
    if (ret < 0) {
        switch (errno) {
            case ENOTSOCK:   /* same as lsock = 0 */
                break;

            default:
                dbg_perror("getsockopt(3)");
                return (-1);
        }
    } else if (lsock)
        kn->kn_flags |= KNFL_SOCKET_PASSIVE;

#ifdef SO_GET_FILTER
    {
        socklen_t out_len = 0;
        
        /*
         * Test if socket has a filter
         * pcap file descriptors need to be considered as passive sockets as
         * SIOCINQ always returns 0 even if data is available.
         * Looking at SO_GET_FILTER is a good way of doing this.
         */
        ret = getsockopt(fd, SOL_SOCKET, SO_GET_FILTER, NULL, &out_len);
        if (ret < 0) {
            switch (errno) {
                case ENOTSOCK:   /* same as lsock = 0 */
                    break;
                default:
                    dbg_perror("getsockopt(3)");
                    return (-1);
            }
        } else if (out_len)
            kn->kn_flags |= KNFL_SOCKET_PASSIVE;
    }
#endif /* SO_GET_FILTER */

    return (0);
}

char *
epoll_event_dump(struct epoll_event *evt)
{
    static __thread char buf[128];

    if (evt == NULL)
        return "(null)";

#define EPEVT_DUMP(attrib) \
    if (evt->events & attrib) \
       strcat(&buf[0], #attrib" ");

    snprintf(&buf[0], 128, " { data = %p, events = ", evt->data.ptr);
    EPEVT_DUMP(EPOLLIN);
    EPEVT_DUMP(EPOLLOUT);
#if defined(HAVE_EPOLLRDHUP)
    EPEVT_DUMP(EPOLLRDHUP);
#endif
    EPEVT_DUMP(EPOLLONESHOT);
    EPEVT_DUMP(EPOLLET);
    strcat(&buf[0], "}\n");

    return (&buf[0]);
#undef EPEVT_DUMP
}

int
epoll_update(int op, struct filter *filt, struct knote *kn, struct epoll_event *ev)
{
    dbg_printf("op=%d fd=%d events=%s", op, (int)kn->kev.ident,
            epoll_event_dump(ev));
    if (epoll_ctl(filter_epfd(filt), op, kn->kev.ident, ev) < 0) {
        dbg_printf("epoll_ctl(2): %s", strerror(errno));
        return (-1);
    }

    return (0);
}

/*
 * Given a file descriptor, return the path to the file it refers to.
 */
int
linux_fd_to_path(char *buf, size_t bufsz, int fd)
{
    char path[51];    // 6 + 20 + 4 + 20 + 1

    if (snprintf(path, sizeof(path), "/proc/%d/fd/%d", getpid(), fd) < 0)
        return (-1);

    memset(buf, 0, bufsz);
    return (readlink(path, buf, bufsz));
}
