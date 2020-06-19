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

#define _GNU_SOURCE
#include <poll.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/resource.h>
#include "../common/private.h"

#define MONITORING_THREAD_SIGNAL  (SIGRTMIN + 1)


//XXX-FIXME TEMP
const struct filter evfilt_proc = EVFILT_NOTIMPL;

/*
 * Per-thread epoll event buffer used to ferry data between
 * kevent_wait() and kevent_copyout().
 */
static __thread struct epoll_event epoll_events[MAX_KEVENT];

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
 *
 * @note Values in the fd_map are never cleared, as we still need to decrement
 * fd_use_cnt when signals for a particular FD are received.
 */
static int *fd_map;

/*
 * Map kqueue id to counter for kq cleanups.
 * When use counter is at 0, cleanup can be performed by signal handler.
 * Otherwise, it means cleanup was already performed for this FD in linux_kqueue_free.
 */
static unsigned int *fd_use_cnt;

static int nb_max_fd;

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

static void
linux_kqueue_cleanup(struct kqueue *kq);

static bool end_monitoring_thread = false;

static void
monitoring_thread_kq_cleanup(int signal_fd, bool ignore_use_count)
{
    int fd;
    struct kqueue *kq;

    /*
     * Signal is received for read side of pipe
     * Get FD for write side as it's the kqueue identifier
     */
    fd = fd_map[signal_fd];
    if (fd < 0) {
       /* Should not happen */
        dbg_printf("fd=%i - not a known FD", fd);
        goto check_count;
    }

    kq = kqueue_lookup(fd);
    if (!kq) {
        /* Should not happen */
        dbg_printf("fd=%i - no kqueue associated", fd);
        goto check_count;
    }

    /*
     * If kqueue instance for this FD hasn't been cleaned yet
     *
     * The issue the fd_use_cnt array prevents, is where kqueue
     * allocates a KQ, and takes the opportunity to cleanup an
     * old KQ instance, and this happens before the monitoring
     * thread is woken up to reap the KQ itself.
     *
     * If the KQ has already been freed, we don't want to do
     * anything here, as that will destroy the newly allocated
     * KQ that shares an identifier with the old KQ.
     *
     * It's a counter because multiple signals may be queued.
     */
    if (ignore_use_count || (fd_use_cnt[fd] == 0)) {
        dbg_printf("kq=%p - fd=%i use_count=%u cleaning up...", kq, fd, fd_use_cnt[fd]);
        kqueue_free(kq);
    } else {
        dbg_printf("kq=%p - fd=%i use_count=%u skipping...", kq, fd, fd_use_cnt[fd]);
    }

check_count:
    /*
     * Forcefully cleaning up like this breaks use counting
     * so we reset the use count to 0, and don't allow it to
     * go below 0 if we later receive delayed signals.
     */
    if (ignore_use_count) {
        fd_use_cnt[fd] = 0;
    } else if (fd_use_cnt[fd] > 0) {
        fd_use_cnt[fd]--; /* Decrement use counter as signal handler has been run for this FD */
    }

    /*
     * Stop thread if all kqueues have been closed
     */
    if (kqueue_cnt == 0) end_monitoring_thread = true;
}

static void
monitoring_thread_cleanup(void *arg)
{
    int i;

    /* Reset so that thread can be restarted */
    monitoring_thread_initialized = PTHREAD_ONCE_INIT;

    for (i = 0; i < nb_max_fd; i++) {
        if (fd_use_cnt[i] > 0) {
            int fd;

            fd = fd_map[i];
            dbg_printf("Checking rfd=%i wfd=%i", i, fd);
            if (fcntl(fd, F_GETFD) < 0) {
                dbg_printf("fd=%i - forcefully cleaning up, use_count=%u: %s",
                           fd, fd_use_cnt[fd], strerror(errno));
                fd_use_cnt[fd] = 0;
                monitoring_thread_kq_cleanup(i, true);
                fd_use_cnt[fd] = 0;
             }
        }
    }

    dbg_printf("tid=%u - monitoring thread exiting", monitoring_tid);
    /* Free thread resources */
    free(fd_map);
    fd_map = NULL;
    free(fd_use_cnt);
    fd_use_cnt = NULL;

    (void) pthread_mutex_unlock(&kq_mtx);
}

/*
 * Monitoring thread that loops on waiting for signals to be received
 */
static void *
monitoring_thread_loop(void *arg)
{
    int res = 0;
    siginfo_t info;

    int i;

    sigset_t monitoring_sig_set;

    nb_max_fd = get_fd_limit();

    sigemptyset(&monitoring_sig_set);
    sigfillset(&monitoring_sig_set);

    pthread_sigmask(SIG_BLOCK, &monitoring_sig_set, NULL);

    sigemptyset(&monitoring_sig_set);
    sigaddset(&monitoring_sig_set, MONITORING_THREAD_SIGNAL);

    end_monitoring_thread = false;    /* reset */

    monitoring_tid = syscall(SYS_gettid);

    dbg_printf("tid=%u - monitoring thread started", monitoring_tid);

    fd_map = calloc(nb_max_fd, sizeof(int));
    if (fd_map == NULL) {
    error:
        return NULL;
    }
    for (i = 0; i < nb_max_fd; i++)
        fd_map[i] = -1;

    fd_use_cnt = calloc(nb_max_fd, sizeof(unsigned int));
    if (fd_use_cnt == NULL){
        free(fd_map);
        goto error;
    }

    /*
     * Now that thread is initialized, let kqueue init resume
     *
     * For some obscure reason this needs to be a broadcast
     * not a signal, else we occasionally get hangs.
     */
    pthread_cond_broadcast(&monitoring_thread_cond);
    pthread_detach(pthread_self());

    pthread_cleanup_push(monitoring_thread_cleanup, NULL)
    while (true) {
        /*
         * Wait for signal notifying us that a change has occured on the pipe
         * It's not possible to only listen on FD close but no other operation
         * should be performed on the kqueue.
         */
        res = sigwaitinfo(&monitoring_sig_set, &info);
        (void) pthread_mutex_lock(&kq_mtx);
        if (res != -1) {
            dbg_printf("fd=%i - freeing kqueue due to fd closure", fd_map[info.si_fd]);
            monitoring_thread_kq_cleanup(info.si_fd, false);
        } else {
            dbg_perror("sigwaitinfo returned early");
        }

        if (end_monitoring_thread)
            break;

        (void) pthread_mutex_unlock(&kq_mtx);
    }
    pthread_cleanup_pop(true);

    return NULL;
}

static void
linux_kqueue_start_thread(void)
{
    static pthread_mutex_t  mt_mtx = PTHREAD_MUTEX_INITIALIZER;

    pthread_mutex_lock(&mt_mtx);

    if (pthread_create(&monitoring_thread, NULL, &monitoring_thread_loop, NULL)) {
         dbg_perror("linux_kqueue_start_thread failure");
    }

    /* Wait for thread creating to be done as we need monitoring_tid to be available */
    pthread_cond_wait(&monitoring_thread_cond, &mt_mtx);
    pthread_mutex_unlock(&mt_mtx);
}

int
linux_kqueue_init(struct kqueue *kq)
{
    struct f_owner_ex sig_owner;
    int flags;

    kq->epollfd = epoll_create(1);
    if (kq->epollfd < 0) {
        dbg_perror("epoll_create(2)");
        return (-1);
    }

    /*
     * The standard behaviour when closing a kqueue fd is
     * for the underlying resources to be freed.
     * In order to catch the close on the libkqueue fd,
     * we use a pipe and return the write end as kq_id.
     * Closing the end will cause the pipe to be close which
     * will be caught by the monitoring thread.
     */
    if (pipe(kq->pipefd)) {
        if (close(kq->epollfd) < 0)
            dbg_perror("close(2)");
        kq->epollfd = -1;

        return (-1);
    }

    if (filter_register_all(kq) < 0) {
    error:
        if (close(kq->epollfd) < 0)
            dbg_perror("close(2)");
        kq->epollfd = -1;

        if (close(kq->pipefd[0]) < 0)
            dbg_perror("close(2)");
        kq->pipefd[0] = -1;

        if (close(kq->pipefd[1]) < 0)
            dbg_perror("close(2)");
        kq->pipefd[1] = -1;

        return (-1);
    }

    /*
     * Ensure pipe ends are non-blocking so that there's
     * no chance of them delaying close().
     */
    if ((fcntl(kq->pipefd[0], F_SETFL, O_NONBLOCK) < 0) ||
        (fcntl(kq->pipefd[1], F_SETFL, O_NONBLOCK) < 0)) {
        dbg_perror("fcntl(2)");
        goto error;
    }

    kq->kq_id = kq->pipefd[1];

    /*
     * Setting O_ASYNC means a signal (SIGIO) will be sent
     * whenever I/O is possible OR when the other end of the
     * pipe has been closed.
     */
    flags = fcntl(kq->pipefd[0], F_GETFL, 0);
    if (fcntl(kq->pipefd[0], F_SETFL, flags | O_ASYNC) < 0) {
        dbg_printf("fd=%i - failed setting FSETFL O_ASYNC (%i): %s", kq->pipefd[0], flags, strerror(errno));
        goto error;
    }

    /*
     * SIGIO may be used by the application, so we use F_SETSIG
     * to change the signal sent to one in the realtime range
     * which are all user defined.
     *
     * We may want to make this configurable at runtime later
     * so we won't conflict with the application.
     */
    if (fcntl(kq->pipefd[0], F_SETSIG, MONITORING_THREAD_SIGNAL) < 0) {
        dbg_printf("fd=%i - failed settting F_SETSIG sig=%u: %s",
                   kq->pipefd[0], MONITORING_THREAD_SIGNAL, strerror(errno));
        goto error;
    }

    (void) pthread_mutex_lock(&kq_mtx);

    /*
     * Increment kqueue counter - must be incremented before
     * starting the monitoring thread in case there's a spurious
     * wakeup and the thread immediately checks that there
     * are no kqueues, and exits.
     */
    kqueue_cnt++;

    /* Start monitoring thread during first initialization */
    (void) pthread_once(&monitoring_thread_initialized, linux_kqueue_start_thread);

    /* Update pipe FD map */
    fd_map[kq->pipefd[0]] = kq->pipefd[1];

    dbg_printf("active_kqueues=%u", kqueue_cnt);

    assert(monitoring_tid != 0);

    /*
     * Finally, ensure that signals generated by I/O operations
     * on the FD get dispatch to the monitoring thread, and
     * not anywhere else.
     */
    sig_owner.type = F_OWNER_TID;
    sig_owner.pid = monitoring_tid;
    if (fcntl(kq->pipefd[0], F_SETOWN_EX, &sig_owner) < 0) {
        dbg_printf("fd=%i - failed settting F_SETOWN to tid=%u: %s", monitoring_tid, kq->pipefd[0], strerror(errno));
        kqueue_cnt--;
        (void) pthread_mutex_unlock(&kq_mtx);
        goto error;
    }
    dbg_printf("kq=%p - monitoring fd=%i for closure", kq, kq->pipefd[0]);

    (void) pthread_mutex_unlock(&kq_mtx);

    return (0);
}

/*
 * Cleanup kqueue resources
 * Should be done while holding kq_mtx
 * return
 * - true if epoll fd and pipes were closed
 * - false if epoll fd was already closed
 */
static void
linux_kqueue_cleanup(struct kqueue *kq)
{
    char buffer;
    ssize_t ret;
    int pipefd;

    if (kq->epollfd > 0) {
        dbg_printf("epoll_fd=%i - closed", kq->epollfd);

        if (close(kq->epollfd) < 0)
            dbg_perror("close(2)");
        kq->epollfd = -1;
    }

    /*
     * read will return 0 on pipe EOF (i.e. if the write end of the pipe has been closed)
     *
     * kq->pipefd[1] should have already been called outside of libkqueue
     * as a signal the kqueue should be closed.
     */
    ret = read(kq->pipefd[0], &buffer, 1);
    if (ret == -1 && errno == EWOULDBLOCK) {
        // Shoudn't happen unless kqops.kqueue_free is called on an open FD
        dbg_puts("kqueue wasn't closed");

        if (close(kq->pipefd[1]) < 0)
            dbg_perror("close(2)");
        kq->pipefd[1] = -1;
    } else if (ret > 0) {
        // Shouldn't happen unless data is written to kqueue FD
        // Ignore write and continue with close
        dbg_puts("unexpected data available on kqueue FD");
        assert(0);
    }

    pipefd = kq->pipefd[0];
    if (pipefd > 0) {
        dbg_printf("kq_fd=%i - closed", pipefd);

        if (close(pipefd) < 0)
            dbg_perror("close(2)");
        kq->pipefd[0] = -1;
    }

    /* Decrement kqueue counter */
    kqueue_cnt--;
    dbg_printf("kq=%p - cleaned up kqueue, active_kqueues=%u", kq, kqueue_cnt);
}

/** Explicitly free the kqueue
 *
 * This is only called from the public kqueue function when a map
 * slot is going to be re-used, so it's an indicator that the
 * KQ fd is in use, and we shouldn't attempt to free it if we
 * receive a signal in the monitoring thread.
 */
void
linux_kqueue_free(struct kqueue *kq)
{
    linux_kqueue_cleanup(kq);
    fd_use_cnt[kq->kq_id]++;
    dbg_printf("kq=%p - increased fd=%i use_count=%u", kq, kq->kq_id, fd_use_cnt[kq->kq_id]);
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
    fds.fd = kqueue_epoll_fd(kq);
    fds.events = POLLIN;

    n = ppoll(&fds, 1, timeout, NULL);
#else
    int epoll_fd;
    fd_set fds;

    dbg_printf("waiting for events (timeout=%ld sec %ld nsec)",
            timeout->tv_sec, timeout->tv_nsec);

    epoll_fd = kqueue_epoll_fd(kq);
    FD_ZERO(&fds);
    FD_SET(epoll_fd, &fds);
    n = pselect(epoll_fd + 1, &fds, NULL , NULL, timeout, NULL);
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
linux_kevent_wait(struct kqueue *kq, int nevents, const struct timespec *ts)
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
    nret = epoll_wait(kqueue_epoll_fd(kq), epoll_events, nevents, timeout);
    if (nret < 0) {
        dbg_perror("epoll_wait");
        return (-1);
    }

    return (nret);
}

static inline int linux_kevent_copyout_ev(struct kevent **el_p, struct epoll_event *ev,
                                          struct filter *filt, struct knote *kn)
{
    int rv;
    struct kevent *el = *el_p;

    rv = filt->kf_copyout(el, kn, ev);
    if (unlikely(rv < 0)) {
        dbg_puts("knote_copyout failed");
        assert(0);
        return rv;
    }

    /*
     *    Advance to the next el entry
     */
    if (likely(el->filter != 0)) {
        (*el_p)++;
    } else {
        dbg_puts("spurious wakeup, discarding event");
    }

    /*
     * Certain flags cause the associated knote to be deleted
     * or disabled.
     */
    if (el->flags & EV_DISPATCH)
        knote_disable(filt, kn); //FIXME: Error checking
    if (el->flags & EV_ONESHOT) {
        knote_delete(filt, kn); //FIXME: Error checking
    }

    return rv;
}

int
linux_kevent_copyout(struct kqueue *kq, int nready, struct kevent *el, int nevents)
{
    struct kevent   *el_p = el, *el_end = el + nevents;
    int             i;

    for (i = 0; i < nready; i++) {
        struct epoll_event    *ev = &epoll_events[i];    /* Thread local storage populated in linux_kevent_wait */
        struct epoll_udata    *epoll_udata = ev->data.ptr;
        int                   rv;

        if (!epoll_udata) {
            dbg_puts("event has no filter, skipping...");
            continue;
        }

        switch (epoll_udata->ud_type) {
        /*
         * epoll event is associated with a single filter
         * so we just have the one knote.
         */
        case EPOLL_UDATA_KNOTE:
        {
            struct knote *kn = epoll_udata->ud_kn;

            if (el_p >= el_end) {
            oos:
                dbg_printf("no more available kevent slots, used %zu", el_p - el);
                goto done;
            }

            rv = linux_kevent_copyout_ev(&el_p, ev, &kq->kq_filt[~(kn->kev.filter)], kn);
            if (rv < 0) goto done;
        }
            break;

        /*
         * epoll event is associated with one filter for
         * reading and one filter for writing.
         */
        case EPOLL_UDATA_FD_STATE:
        {
            struct fd_state      *fds = epoll_udata->ud_fds;
            struct knote         *kn;

            /*
             *    FD is readable
             */
            if (ev->events & EPOLLIN) {
                if (el_p >= el_end) goto oos;

                kn = fds->fds_read;

                /*
                 * We shouldn't receive events we didn't register for
                 * This assume's the Linux's epoll implementation isn't
                 * complete garbage... so um... this assert may need
                 * to be removed later.
                 */
                assert(kn);

                rv = linux_kevent_copyout_ev(&el_p, ev, &kq->kq_filt[~(kn->kev.filter)], kn);
                if (rv < 0) goto done;
            }

            /*
             *    FD is writable
             */
            if (ev->events & EPOLLOUT) {
                if (el_p >= el_end) goto oos;

                kn = fds->fds_write;

                assert(kn);    /* We shouldn't receive events we didn't request */

                rv = linux_kevent_copyout_ev(&el_p, ev, &kq->kq_filt[~(kn->kev.filter)], kn);
                if (rv < 0) goto done;
            }
        }
            break;

        /*
         *    Bad udata value. Maybe use after free?
         */
        default:
            assert(0);
            return (-1);
        }
    }

done:
    return el_p - el;
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
        if (close(evfd) < 0)
            dbg_perror("close(2)");
        return (-1);
    }
    e->ef_id = evfd;

    return (0);
}

void
linux_eventfd_close(struct eventfd *e)
{
    if (close(e->ef_id) < 0)
        dbg_perror("close(2)");
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
            dbg_printf("fd=%i is a regular file", fd);
            kn->kn_flags |= KNFL_FILE;
            return (0);

        case S_IFIFO:
            dbg_printf("fd=%i is a pipe", fd);
            kn->kn_flags |= KNFL_PIPE;
            return (0);

        case S_IFBLK:
            dbg_printf("fd=%i is a block device", fd);
            kn->kn_flags |= KNFL_BLOCKDEV;
            return (0);

        case S_IFCHR:
            dbg_printf("fd=%i is a character device", fd);
            kn->kn_flags |= KNFL_CHARDEV;
            return (0);

        case S_IFSOCK:
            dbg_printf("fd=%i is a socket", fd);
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
            dbg_printf("fd=%i is a stream socket", fd);
            kn->kn_flags |= KNFL_SOCKET_STREAM;
            break;

        case SOCK_DGRAM:
            dbg_printf("fd=%i is a datagram socket", fd);
            kn->kn_flags |= KNFL_SOCKET_DGRAM;
            break;

        case SOCK_RDM:
            dbg_printf("fd=%i is a reliable datagram socket", fd);
            kn->kn_flags |= KNFL_SOCKET_RDM;
            break;

        case SOCK_SEQPACKET:
            dbg_printf("fd=%i is a sequenced and reliable datagram socket", fd);
            kn->kn_flags |= KNFL_SOCKET_SEQPACKET;
            break;

        case SOCK_RAW:
            dbg_printf("fd=%i is a raw socket", fd);
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

char *epoll_event_op_dump(int op)
{
    static __thread char buf[14];

    buf[0] = '\0';

#define EPOP_DUMP(attrib) \
    if (op == attrib) { \
        strcpy(buf, #attrib); \
        return buf; \
    }

    EPOP_DUMP(EPOLL_CTL_MOD);
    EPOP_DUMP(EPOLL_CTL_ADD);
    EPOP_DUMP(EPOLL_CTL_DEL);

    return buf;
}

char *epoll_event_flags_dump(int events)
{
    static __thread char buf[128];

    buf[0] = '\0';

#define EPEVT_DUMP(attrib) \
    if (events & attrib) strcat(buf, #attrib" ");

    EPEVT_DUMP(EPOLLIN);
    EPEVT_DUMP(EPOLLOUT);
#if defined(HAVE_EPOLLRDHUP)
    EPEVT_DUMP(EPOLLRDHUP);
#endif
    EPEVT_DUMP(EPOLLONESHOT);
    EPEVT_DUMP(EPOLLET);

    if (buf[0] != '\0') buf[strlen(buf) - 1] = '\0';    /* Trim trailing space */

    return buf;
}

char *
epoll_event_dump(struct epoll_event *evt)
{
    static __thread char buf[128];

    if (evt == NULL)
        return "(null)";

    snprintf(buf, sizeof(buf), "{ data = %p, events = %s }", evt->data.ptr, epoll_event_flags_dump(evt->events));

    return (buf);
#undef EPEVT_DUMP
}

/** Determine if two fd state entries are equal
 *
 * @param[in] a           first entry.
 * @param[in] b           second entry.
 * @return
 *        - 0 if fd is equal.
 *        - 1 if fd_a > fd_b
 *        - -1 if fd_a < fd_b
 */
static int
epoll_fd_state_cmp(struct fd_state *a, struct fd_state *b)
{
    return (a->fds_fd > b->fds_fd) - (a->fds_fd < b->fds_fd); /* branchless comparison */
}

/** Create type specific rbtree functions
 *
 */
RB_GENERATE(fd_st, fd_state, fds_entries, epoll_fd_state_cmp)

/** Determine current fd_state/knote associations
 *
 * @param[in,out] fds_p   to query.  If *fds_p is NULL and
 *                          kn->kn_fds is NULL, we attempt a
 *                          lookup based on the FD associated with
 *                          the kn.
 * @param[in] kn          to return EPOLLIN|EPOLLOUT flags for.
 * @param[in] disabled    if true, only disabled knotes will
 *                        be included in the set.
 *                        if false, only enabled knotes will
 *                        be included in the set.
 * @return
 *    - EPOLLIN     if the FD has a read knote associated with it.
 *    - EPOLLOUT    if the FD has a write knote associated with it.
 */
int epoll_fd_state(struct fd_state **fds_p, struct knote *kn, bool disabled)
{
    int             state = 0;
    int             fd = kn->kev.ident;
    struct fd_state *fds = *fds_p;

    if (!fds) {
        fds = kn->kn_fds;
        if(fds) dbg_printf("fd_state: from-kn fd=%i", fd);
    }
    if (!fds) {
        dbg_printf("fd_state: find fd=%i", fd);

        fds = RB_FIND(fd_st, &kn->kn_kq->kq_fd_st, &(struct fd_state){ .fds_fd = fd });
        if (!fds) return (0);
    }

    *fds_p = fds;

    if (fds->fds_read && (disabled == ((kn->kev.flags & EV_DISABLE) != 0))) state |= EPOLLIN;
    if (fds->fds_write && (disabled == ((kn->kev.flags & EV_DISABLE) != 0))) state |= EPOLLOUT;

    return state;
}

/** Associate a knote with the fd_state
 *
 * @param[in,out] fds_p   to modify knote associations for.
 *                        If *fds_p is NULL and kn->kn_fds is
 *                        NULL, we attempt a lookup based on
 *                        the FD associated with the kn.
 * @param[in] kn          to add FD tracking entry for.
 * @param[in] ev          the file descriptor was registered for,
 *                        either EPOLLIN or EPOLLOUT.
 * @return
 *    - 0 on success.
 *    - -1 on failure.
 */
int epoll_fd_state_mod(struct fd_state **fds_p, struct knote *kn, int ev)
{
    struct kqueue       *kq = kn->kn_kq;
    int                    fd = kn->kev.ident;
    struct fd_state     *fds = *fds_p;

    assert(ev & (EPOLLIN | EPOLLOUT));

    /*
     * The kqueue_lock around copyin and copyout
     * operations means we don't need mutexes
     * around tree access.
     *
     * Only one thread can be copying in or copying
     * out at a time.
     *
     * The only potential issue we have were
     * modifying the tree in kevent_wait
     * (which we're not).
     */
    if (!fds) fds = kn->kn_fds;
    if (!fds) {
        /*
         * Also used as an initialiser if we can't find
         * an existing fd_state.
         */
        struct fd_state     query = { .fds_fd = fd };

        fds = RB_FIND(fd_st, &kq->kq_fd_st, &query);
        if (!fds) {
            dbg_printf("fd_state: new fd=%i events=0x%04x (%s)", fd, ev, epoll_event_flags_dump(ev));

            fds = malloc(sizeof(struct fd_state));
            if (!fds) return (-1);

            *fds = query;
            FDS_UDATA(fds);    /* Prepare for insertion into epoll */
            RB_INSERT(fd_st, &kq->kq_fd_st, fds);

        } else {
        mod:
            dbg_printf("fd_state: mod fd=%i events=0x%04x (%s)", fd, ev, epoll_event_flags_dump(ev));
        }
    } else goto mod;

    /*
     * Place the knote in the correct slot.
     */
    if (ev & EPOLLIN) {
        assert(!fds->fds_read || (fds->fds_read == kn));
        fds->fds_read = kn;
    }
    if (ev & EPOLLOUT) {
        assert(!fds->fds_write || (fds->fds_write == kn));
        fds->fds_write = kn;
    }

    kn->kn_fds = fds;
    *fds_p = fds;

    return (0);
}

/** Disassociate a knote from an fd_ev possibly freeing the fd_ev
 *
 * @param[in] kn   to remove FD tracking entry for.
 * @param[in] ev   the file descriptor was de-registered for,
 *                 either EPOLLIN or EPOLLOUT.
 */
void epoll_fd_state_del(struct fd_state **fds_p, struct knote *kn, int ev)
{
    struct fd_state     *fds = kn->kn_fds;
    struct kqueue       *kq = kn->kn_kq;

    assert(ev & (EPOLLIN | EPOLLOUT));
    assert(fds); /* There ~must~ be an entry else something has gone horribly wrong */
    assert(!*fds_p || (*fds_p == kn->kn_fds));

    /*
     * copyin/copyout lock means we don't need
     * to protect operations here.
     */
    if (ev & EPOLLIN) {
        assert(fds->fds_read);
        fds->fds_read = NULL;
    }

    if (ev & EPOLLOUT) {
        assert(fds->fds_write);
        fds->fds_write = NULL;
    }

    if (!fds->fds_read && !fds->fds_write) {
        dbg_printf("fd_state: rm fd=%i", fds->fds_fd);
        RB_REMOVE(fd_st, &kq->kq_fd_st, fds);
        free(fds);
        *fds_p = NULL;
    } else {
        dbg_printf("fd_state: mod fd=%i events=0x%04x (%s)", fds->fds_fd, ev, epoll_event_flags_dump(ev));
    }
    kn->kn_fds = NULL;
}

bool
epoll_fd_registered(struct filter *filt, struct knote *kn)
{
    struct fd_state    *fds = NULL;
    int fd = kn->kev.ident;
    int have_ev;

    /*
     * The vast majority of the time if the knote
     * has already been removed then kn->kn_fds
     * will be false.
     */
    if (!kn->kn_fds) return false;        /* No file descriptor state, can't be in epoll */

    have_ev = epoll_fd_state(&fds, kn, false);            /* ...enabled only */
    if (!have_ev) return false;

    /*
     * This *SHOULD* be a noop if the FD is already
     * registered.
     */
    if (epoll_ctl(filter_epoll_fd(filt), EPOLL_CTL_MOD, fd, EPOLL_EV_FDS(have_ev, fds)) < 0) return false;

    return true;
}
int
epoll_update(int op, struct filter *filt, struct knote *kn, int ev, bool delete)
{
    struct fd_state *fds = NULL;
    int have_ev, want, want_ev;
    int opn;
    int fd;

    fd = kn->kev.ident;

#define EV_EPOLLINOUT(_x) ((_x) & (EPOLLIN | EPOLLOUT))

    if (kn->kev.flags & EV_DISABLE) dbg_printf("fd=%i kn=%p is disabled", fd, kn);

    /*
     * Determine the current state of the file descriptor
     * and see if we need to make changes.
     */
    have_ev = epoll_fd_state(&fds, kn, false);            /* ...enabled only */

    dbg_printf("fd=%i have_ev=0x%04x (%s)", fd, have_ev, epoll_event_flags_dump(have_ev));
    switch (op) {
    case EPOLL_CTL_ADD:
        want = have_ev | ev;            /* This also preserves other option flags */
        break;

    case EPOLL_CTL_DEL:
        want = have_ev & ~ev;           /* No options for delete */

        /*
         * If we're performing a delete we need
         * to check for previously disabled
         * knotes that may now be being deleted.
         */
        if (delete) {
            int to_delete;

            to_delete = epoll_fd_state(&fds, kn, true); /* ...disabled only */
            dbg_printf("fd=%i disabled_ev=0x%04x (%s)", fd, to_delete, epoll_event_flags_dump(to_delete));
            to_delete &= EV_EPOLLINOUT(ev);

            if (to_delete) {
                dbg_printf("fd=%i ev=%i removing disabled fd state", fd, op);
                epoll_fd_state_del(&fds, kn, to_delete);
            }
        }
        break;

    case EPOLL_CTL_MOD:
        want = ev;                   /* We assume the caller knows what its doing... */

        if (delete) {
            int to_delete;

            to_delete = epoll_fd_state(&fds, kn, true); /* ...disabled only */
            dbg_printf("fd=%i disabled_ev=0x%04x (%s)", fd, to_delete, epoll_event_flags_dump(to_delete));
            to_delete &= ~ev;

            if (to_delete) {
                dbg_printf("fd=%i ev=%i removing disabled fd state", fd, op);
                epoll_fd_state_del(&fds, kn, to_delete);
            }
        }
        break;

    default:
        assert(0);
        return (-1);
    }

    /*
     * We only want the read/write flags for comparisons.
     */
    want_ev = EV_EPOLLINOUT(want);
     if (!have_ev && want_ev) {        /* There's no events registered and we want some */
        opn = EPOLL_CTL_ADD;
        epoll_fd_state_mod(&fds, kn, want_ev & ~have_ev);
    }
    else if (have_ev && !want_ev)       /* We have events registered but don't want any */
        opn = EPOLL_CTL_DEL;
    else if (have_ev != want_ev)        /* There's events but they're not what we want */
        opn = EPOLL_CTL_MOD;
    else
        return (0);

    dbg_printf("fd=%i op=0x%04x (%s) opn=0x%04x (%s) %s",
               fd,
               op, epoll_event_op_dump(op),
               opn, epoll_event_op_dump(opn),
               epoll_event_dump(EPOLL_EV_FDS(want, fds)));

    if (epoll_ctl(filter_epoll_fd(filt), opn, fd, EPOLL_EV_FDS(want, fds)) < 0) {
        dbg_printf("epoll_ctl(2): %s", strerror(errno));

        switch (opn) {
        case EPOLL_CTL_ADD:
            epoll_fd_state_del(&fds, kn, want_ev & ~have_ev);
            break;

        case EPOLL_CTL_DEL:
        case EPOLL_CTL_MOD:
            /*
             * File descriptor went away and we weren't notified
             * not necessarily an error.
             */
            if (errno == EBADF) {
                int kn_ev = 0;

                if (kn == fds->fds_read) {
                    kn_ev = EPOLLIN;
                } else if (kn == fds->fds_write) {
                    kn_ev = EPOLLOUT;
                }
                kn_ev &= ~want_ev;    /* If it wasn't wanted... */

                if (kn_ev) {
                    dbg_printf("clearing fd=%i fds=%p ev=%s", fd, fds, epoll_event_flags_dump(kn_ev));
                    epoll_fd_state_del(&fds, kn, kn_ev);
                    return (0);
                }
            }
            break;
        }

        return (-1);
    }

    /*
     * Only change fd state for del and mod on success
     * we need to 'add' before so that we get the fd_state
     * structure to pass in to epoll.
     */
    switch (opn) {
    case EPOLL_CTL_DEL:
        if (delete) {
            dbg_printf("fd=%i ev=%i removing fd state", fd, op);
            epoll_fd_state_del(&fds, kn, have_ev & ~want_ev);      /* We rely on the caller to mark the knote as disabled */
        }
        break;

    case EPOLL_CTL_MOD:
    {
        int add, del;

        add = want_ev & ~have_ev;
        del = have_ev & ~want_ev;

        if (add) epoll_fd_state_mod(&fds, kn, add);
        if (del && delete) {
            dbg_printf("fd=%i ev=%i removing fd state", fd, op);
            epoll_fd_state_del(&fds, kn, del);                 /* We rely on the caller to mark the knote as disabled */
        }
    }
        break;
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
