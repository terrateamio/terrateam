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
#include <signal.h>

#include <inttypes.h>
#include <sys/prctl.h>
#include <sys/resource.h>

#include "../common/private.h"

#define MONITORING_THREAD_SIGNAL  (SIGRTMIN + 1)

/*
 * Per-thread epoll event buffer used to ferry data between
 * kevent_wait() and kevent_copyout().
 */
static __thread struct epoll_event epoll_events[MAX_KEVENT];

/*
 * Monitoring thread that takes care of cleaning up kqueues (on linux only)
 */
static pthread_t monitoring_thread;
static pid_t monitoring_tid; /* Monitoring thread */

static pthread_mutex_t monitoring_thread_mtx = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t monitoring_thread_cond = PTHREAD_COND_INITIALIZER;

enum thread_exit_state {
    THREAD_EXIT_STATE_SELF_CANCEL = 0,
    THREAD_EXIT_STATE_CANCEL_LOCKED,
    THREAD_EXIT_STATE_CANCEL_UNLOCKED,
};

/*
 * Monitoring thread is exiting because the process is terminating
 */
static enum thread_exit_state monitoring_thread_state;

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
 * Otherwise, it means cleanup was already performed for this FD in linux_kqueue_reused.
 */
static unsigned int *fd_use_cnt;

static int nb_max_fd;

static void
linux_kqueue_free(struct kqueue *kq);

static void
monitoring_thread_cleanup(UNUSED void *arg)
{
    struct kqueue *kq, *kq_tmp;

    /*
     * If the entire process is exiting, then free all
     * the kqueues
     *
     * We do this because we don't reliably receive all the
     * close MONITORING_THREAD_SIGNALs before the process
     * exits, and this avoids ASAN or valgrind raising
     * spurious memory leaks.
     *
     * If the user _hasn't_ closed a KQ fd, then we don't
     * free the underlying memory, and it'll be correctly
     * reported as a memory leak.
     */
    if ((monitoring_thread_state == THREAD_EXIT_STATE_CANCEL_LOCKED) ||
        (monitoring_thread_state == THREAD_EXIT_STATE_CANCEL_UNLOCKED)) {

        /*
         * Keep the assertion in kqueue_free happy
         */
        if (monitoring_thread_state == THREAD_EXIT_STATE_CANCEL_UNLOCKED)
            tracing_mutex_lock(&kq_mtx);

        LIST_FOREACH_SAFE(kq, &kq_list, kq_entry, kq_tmp) {
            /*
             * We only cleanup kqueues where their file descriptor
             * has been closed.
             *
             * This is necessary because we can be told to exit
             * before the monitoring thread has a chance to process
             * the signal indicating that a kqueue has been
             * cleaned up, and this can lead to spurious reports
             * from LSAN.
             *
             * We only cleanup kqueues where the file descriptor has
             * been closed, because other kqueues may be in the
             * middle of operations with kq->kq_mtx held, and
             * attempting to clean them up would cause a deadlock.
             *
             * These kqueues are legitimate leaks, and should have
             * been freed by the user application before it exited.
             */
            dbg_printf("kq=%p - fd=%i explicitly checking for closeure", kq, kq->kq_id);
            if (fcntl(kq->kq_id, F_GETFD) < 0) {
                dbg_printf("kq=%p - fd=%i forcefully cleaning up, current use_count=%u: %s",
                           kq,
                           kq->kq_id, fd_use_cnt[kq->kq_id],
                           errno == EBADF ? "File descriptor already closed" : strerror(errno));
                fd_use_cnt[kq->kq_id] = 0;
            } else {
                /*
                 * If there's no use cnt for the kqueue then something
                 * has gone very wrong.
                 */
                assert(fd_use_cnt[kq->kq_id] > 0);
            }

            if (fd_use_cnt[kq->kq_id] == 0) {
                dbg_printf("kq=%p - fd=%i use_count=%u cleaning up...", kq, kq->kq_id, fd_use_cnt[kq->kq_id]);
                kqueue_free(kq);
            } else {
                dbg_printf("kq=%p - fd=%i is alive use_count=%u.  Skipping, this is likely a leak...",
                           kq, kq->kq_id, fd_use_cnt[kq->kq_id]);
            }
        }

        if (monitoring_thread_state == THREAD_EXIT_STATE_CANCEL_UNLOCKED)
            tracing_mutex_unlock(&kq_mtx);
    }

    dbg_printf("tid=%u - monitoring thread exiting (%s)",
               monitoring_tid,
               monitoring_thread_state == THREAD_EXIT_STATE_SELF_CANCEL ? "no kqueues" : "process term");
    /* Free thread resources */
    free(fd_map);
    fd_map = NULL;
    free(fd_use_cnt);
    fd_use_cnt = NULL;

    /* Reset so that thread can be restarted */
    monitoring_tid = 0;

    if (monitoring_thread_state == THREAD_EXIT_STATE_CANCEL_LOCKED)
        tracing_mutex_unlock(&kq_mtx);
}


/** Clean up a kqueue from the perspective of the monitoring thread
 *
 * Called with the kq_mtx held.
 */
static void
monitoring_thread_kqueue_cleanup(int signal_fd)
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
        return;
    }

    kq = kqueue_lookup(fd);
    if (!kq) {
        /* Should not happen */
        dbg_printf("fd=%i - no kqueue associated", fd);
        assert(0);
        return;
    }

    /*
     * We should never have more pending signals than we have
     * allocated kqueues against a given ID.
     */
    assert(fd_use_cnt[kq->kq_id] > 0);

    /*
     * Decrement use counter as signal handler has been run for
     * this FD.  We rely on using an RT signal so that multiple
     * signals are queued.
     *
     * Use count is tracked with the kq_id.
     */
    fd_use_cnt[kq->kq_id]--;

    /*
     * If kqueue instance for this FD hasn't been cleaned up yet
     *
     * When the main kqueue code frees a kq, the file descriptor
     * of the kq often gets reused.
     *
     * We maintain a count of how many allocations have been
     * performed against a given file descriptor ID, and only
     * free the kqueue here if that count is zero.
     */
    if (fd_use_cnt[kq->kq_id] == 0) {
        dbg_printf("kq=%p - fd=%i use_count=%u cleaning up...", kq, fd, fd_use_cnt[kq->kq_id]);
        kqueue_free(kq);
    } else {
        dbg_printf("kq=%p - fd=%i use_count=%u skipping...", kq, fd, fd_use_cnt[kq->kq_id]);
    }
}

/*
 * Monitoring thread that loops on waiting for signals to be received
 */
static void *
monitoring_thread_loop(UNUSED void *arg)
{
    int res = 0;
    siginfo_t info;

    int i;

    sigset_t monitoring_sig_set;

    /* Set the thread's name to something descriptive so it shows up in gdb,
     * etc. glibc >= 2.1.2 supports pthread_setname_np, but this is a safer way
     * to do it for backwards compatibility. Max name length is 16 bytes. */
    prctl(PR_SET_NAME, "libkqueue_mon", 0, 0, 0);

    nb_max_fd = get_fd_limit();

    sigemptyset(&monitoring_sig_set);
    sigfillset(&monitoring_sig_set);

    pthread_sigmask(SIG_BLOCK, &monitoring_sig_set, NULL);

    sigemptyset(&monitoring_sig_set);
    sigaddset(&monitoring_sig_set, MONITORING_THREAD_SIGNAL);

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
     */
    pthread_mutex_lock(&monitoring_thread_mtx);    /* Must try to lock to ensure parent is waiting on signal */
    pthread_cond_signal(&monitoring_thread_cond);
    pthread_mutex_unlock(&monitoring_thread_mtx);

    monitoring_thread_state = THREAD_EXIT_STATE_CANCEL_UNLOCKED;
    pthread_cleanup_push(monitoring_thread_cleanup, NULL)
    while (true) {
        /*
         * Wait for signal notifying us that a change has occured on the pipe
         * It's not possible to only listen on FD close but no other operation
         * should be performed on the kqueue.
         */
        res = sigwaitinfo(&monitoring_sig_set, &info);
        if (res == -1) {
            dbg_printf("sigwaitinfo(2): %s", strerror(errno));
            continue;
        }

        /*
         * Don't allow cancellation in the middle of cleaning up resources
         */
        pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, NULL);
        tracing_mutex_lock(&kq_mtx);
        dbg_printf("fd=%i - freeing kqueue due to fd closure (signal) for sfd=%i ", fd_map[info.si_fd], info.si_fd);

        /*
         * Release resources used by this kqueue
         */
        monitoring_thread_kqueue_cleanup(info.si_fd);

        /*
         * Exit if there are no more kqueues to monitor
         */
        if (kq_cnt == 0)
            break;

        tracing_mutex_unlock(&kq_mtx);
        pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, NULL);
    }

    /*
     * Ensure that any cancellation requests are acted on
     */
    monitoring_thread_state = THREAD_EXIT_STATE_CANCEL_LOCKED;
    pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, NULL);
    pthread_testcancel();

    monitoring_thread_state = THREAD_EXIT_STATE_SELF_CANCEL;
    pthread_cleanup_pop(true); /* Executes the cleanup function (monitoring_thread_cleanup) */
    res = pthread_detach(pthread_self());
    if (res != 0)
        dbg_printf("pthread_detach(3): %s", strerror(res));
    tracing_mutex_unlock(&kq_mtx);

    return NULL;
}

static int
linux_kqueue_start_thread(void)
{
    pthread_mutex_lock(&monitoring_thread_mtx);
    if (pthread_create(&monitoring_thread, NULL, monitoring_thread_loop, NULL)) {
         dbg_perror("linux_kqueue_start_thread failure");
         pthread_mutex_unlock(&monitoring_thread_mtx);

         return (-1);
    }
    /* Wait for thread creating to be done as we need monitoring_tid to be available */
    pthread_cond_wait(&monitoring_thread_cond, &monitoring_thread_mtx); /* unlocks mt_mtx allowing child to lock it */
    pthread_mutex_unlock(&monitoring_thread_mtx);

    return (0);
}

/** Free kqueues on fork
 *
 * Called with kq_mtx held.
 */
static void
linux_libkqueue_fork(void)
{
    struct kqueue *kq, *kq_tmp;

    /*
     * We don't have to cancel the monitor thread here
     * as fork() typically only duplicates the thread
     * which called it.
     *
     * Ensure we don't try and cancel it on exit by
     * clearing the thread id.
     *
     * We don't need to lock the kq_mtx here as we're in
     * the child, and none of our threads will have been
     * duplicated.
     */
    monitoring_tid = 0;

    /*
     * If the process has been forked, then we need
     * to destroy all of the kqueue instances in
     * the fork.
     *
     * This replicates the behaviour of real kqueues
     * on FreeBSD, and also prevents spurious leak
     * reports being raised by LSAN.
     */
    LIST_FOREACH_SAFE(kq, &kq_list, kq_entry, kq_tmp) {
        dbg_printf("kq=%p - cleaning up on fork", kq);

        /*
         * There's very limited cleanups we can do
         * here, as we're only allowed to call
         * async-signal-safe functions in this
         * handler.
         *
         * This means any functions which alloc or
         * free memory are ruled out, meaning we
         * can't release any of the memory allocated
         * to the kqueues or filters.
         *
         * Fortunately close() is async-signal-safe.
         */
        close(kq->epollfd);
        kq->epollfd = -1;

        if ((kq->pipefd[0] > 0) && (close(kq->pipefd[0]) < 0))
            dbg_perror("close(2)");
        kq->pipefd[0] = -1;

        if ((kq->pipefd[1] > 0) && (close(kq->pipefd[1]) < 0))
            dbg_perror("close(2)");
        kq->pipefd[1] = -1;
    }
}

/*
 * We have to use this instead of pthread_detach as there
 * seems to be some sort of race with LSAN and thread cleanup
 * on exit, and if we don't explicitly join the monitoring
 * thread, LSAN reports kqueues as leaked.
 */
static void
linux_libkqueue_free(void)
{
    pid_t tid;

    tracing_mutex_lock(&kq_mtx);
    tid = monitoring_tid; /* Gets trashed when the thread exits */
    if (tid) {
        void *retval;
        int ret;

        dbg_printf("tid=%u - cancelling", tid);
        ret = pthread_cancel(monitoring_thread);
        if (ret != 0)
           dbg_printf("tid=%u - cancel failed: %s", tid, strerror(ret));
        /*
         * We unlock here to allow the monitoring thread
         * to continue if it was processing a cleanup.
         */
        tracing_mutex_unlock(&kq_mtx);

        ret = pthread_join(monitoring_thread, &retval);
        if (ret == 0) {
            if (retval == PTHREAD_CANCELED) {
                dbg_printf("tid=%u - joined with exit_status=PTHREAD_CANCELED", tid);
            } else {
                dbg_printf("tid=%u - joined with exit_status=%" PRIdPTR, tid, (intptr_t)retval);
            }
        } else {
            dbg_printf("tid=%u - join failed: %s", tid, strerror(ret));
        }
    }
    else
        tracing_mutex_unlock(&kq_mtx);
}

static int
linux_kqueue_init(struct kqueue *kq)
{
    struct f_owner_ex sig_owner;

    kq->epollfd = epoll_create1(EPOLL_CLOEXEC);
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
    if (pipe2(kq->pipefd, O_CLOEXEC)) {
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
     * O_NONBLOCK - Ensure pipe ends are non-blocking so that
     * there's no chance of them delaying close().
     *
     * O_ASYNC - Raise a SIGIO signal if the file descriptor
     * becomes readable or is closed.
     */
    if ((fcntl(kq->pipefd[0], F_SETFL, O_NONBLOCK | O_ASYNC ) < 0) ||
        (fcntl(kq->pipefd[1], F_SETFL, O_NONBLOCK) < 0)) {
        dbg_perror("fcntl(2)");
        goto error;
    }

    kq->kq_id = kq->pipefd[1];

    /*
     * SIGIO may be used by the application, so we use F_SETSIG
     * to change the signal sent to one in the realtime range
     * which are all user defined.
     *
     * We may want to make this configurable at runtime later
     * so we won't conflict with the application.
     *
     * Note: MONITORING_THREAD_SIGNAL must be >= SIGRTMIN so that
     * multiple signals are queued.
     */
    if (fcntl(kq->pipefd[0], F_SETSIG, MONITORING_THREAD_SIGNAL) < 0) {
        dbg_printf("fd=%i - failed setting F_SETSIG sig=%u: %s",
                   kq->pipefd[0], MONITORING_THREAD_SIGNAL, strerror(errno));
        goto error;
    }

    /* Start monitoring thread during first initialization */
    if (monitoring_tid == 0) {
        if (linux_kqueue_start_thread() < 0)
            goto error;
    }

    /* Update pipe FD map */
    fd_map[kq->pipefd[0]] = kq->kq_id;

    /* Mark this id as in use */
    fd_use_cnt[kq->kq_id]++;

    dbg_printf("kq=%p - fd=%i use_count=%u", kq, kq->kq_id, fd_use_cnt[kq->kq_id]);

    assert(monitoring_tid != 0);

    /*
     * Finally, ensure that signals generated by I/O operations
     * on the FD get dispatch to the monitoring thread, and
     * not anywhere else.
     */
    sig_owner.type = F_OWNER_TID;
    sig_owner.pid = monitoring_tid;
    if (fcntl(kq->pipefd[0], F_SETOWN_EX, &sig_owner) < 0) {
        dbg_printf("fd=%i - failed setting F_SETOWN to tid=%u: %s", monitoring_tid, kq->kq_id, strerror(errno));
        tracing_mutex_unlock(&kq_mtx);
        goto error;
    }
    dbg_printf("kq=%p - monitoring fd=%i for closure", kq, kq->pipefd[0]);

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
linux_kqueue_free(struct kqueue *kq)
{
    char buffer;
    ssize_t ret;
    int pipefd;

    if (kq->epollfd > 0) {
        dbg_printf("epoll_fd=%i - closed", kq->epollfd);

        if (close(kq->epollfd) < 0)
            dbg_perror("close(2) - epoll_fd=%i", kq->epollfd);
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

        if (close(kq->pipefd[1]) < 0) {
            dbg_perror("close(2) - pipefd[1]=%i", kq->pipefd[1]);
        } else {
            dbg_printf("pipefd[1]=%i - closed", kq->pipefd[1]);
        }
        kq->pipefd[1] = -1;
    } else if (ret > 0) {
        // Shouldn't happen unless data is written to kqueue FD
        // Ignore write and continue with close
        dbg_puts("unexpected data available on kqueue FD");
        assert(0);
    }

    pipefd = kq->pipefd[0];
    if (pipefd > 0) {
        if (close(pipefd) < 0) {
            dbg_perror("close(2) - kq_fd=%i", kq->pipefd[0]);
        } else {
            dbg_printf("kq_fd=%i - closed", kq->pipefd[0]);
        }
        kq->pipefd[0] = -1;
    }
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

static int
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

static inline int linux_kevent_copyout_ev(struct kevent *el, int nevents, struct epoll_event *ev,
                                          struct filter *filt, struct knote *kn)
{
    int rv;

    rv = filt->kf_copyout(el, nevents, filt, kn, ev);
    dbg_printf("rv=%i", rv);

    if (unlikely(rv < 0)) {
        dbg_puts("knote_copyout failed");
        assert(0);
        return rv;
    }

    /*
     * Don't emit bad events...
     *
     * Fixme - We shouldn't be emitting bad events
     * in the first place?
     */
    if (unlikely(el->filter == 0)) {
        dbg_puts("spurious wakeup, discarding event");
        rv = 0;
    }

    return rv;
}

char const *epoll_op_dump(int op)
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

static const char *
udata_type(enum epoll_udata_type ud_type)
{
    const char *ud_name[] = {
        [EPOLL_UDATA_KNOTE] = "EPOLL_UDATA_KNOTE",
        [EPOLL_UDATA_FD_STATE] = "EPOLL_UDATA_FD_STATE",
        [EPOLL_UDATA_EVENT_FD] = "EPOLL_UDATA_EVENT_FD",
    };

    if (ud_type < 0 || ud_type >= NUM_ELEMENTS(ud_name))
        return "EPOLL_UDATA_INVALID";
    else
        return ud_name[ud_type];
}

static const char *
epoll_udata_type_dump(const struct epoll_event *ev)
{
    static __thread char buf[64];
    enum epoll_udata_type ud_type;

    ud_type = ((struct epoll_udata *)(ev->data.ptr))->ud_type;

    snprintf(buf, sizeof(buf), "%d (%s)",
             ud_type, udata_type(ud_type));
    return ((const char *) buf);
}

static const char *
epoll_flags_dump(uint32_t events)
{
    static __thread char buf[1024];
    size_t len;

#define EEVENT_DUMP(attrib) \
    if (events & attrib) \
    strncat((char *) buf, #attrib" ", 64);

    snprintf(buf, sizeof(buf), "events=0x%08x (", events);
    EEVENT_DUMP(EPOLLIN);
    EEVENT_DUMP(EPOLLPRI);
    EEVENT_DUMP(EPOLLOUT);
    EEVENT_DUMP(EPOLLRDNORM);
    EEVENT_DUMP(EPOLLRDBAND);
    EEVENT_DUMP(EPOLLWRNORM);
    EEVENT_DUMP(EPOLLWRBAND);
    EEVENT_DUMP(EPOLLMSG);
    EEVENT_DUMP(EPOLLERR);
    EEVENT_DUMP(EPOLLHUP);
    EEVENT_DUMP(EPOLLRDHUP);
    EEVENT_DUMP(EPOLLONESHOT);
    EEVENT_DUMP(EPOLLET);

    len = strlen(buf);
    if (buf[len - 1] == ' ') buf[len - 1] = '\0';    /* Trim trailing space */
    strcat(buf, ")");

#undef EEVENT_DUMP

    return ((const char *) buf);
}

const char *
epoll_event_flags_dump(const struct epoll_event *ev)
{
    return epoll_flags_dump(ev->events);
}

const char *
epoll_event_dump(const struct epoll_event *ev)
{
    static __thread char buf[2147];

    snprintf((char *) buf, sizeof(buf),
             "{ %s, udata=%p, udata_type=%s }",
             epoll_event_flags_dump(ev),
             ev->data.ptr,
             epoll_udata_type_dump(ev));

    return ((const char *) buf);
}

int
linux_kevent_copyout(struct kqueue *kq, int nready, struct kevent *el, int nevents)
{
    struct kevent   *el_p = el, *el_end = el + nevents;
    int             i;

    dbg_printf("got %i events from epoll", nready);

    for (i = 0; i < nready; i++) {
        struct epoll_event    *ev = &epoll_events[i];    /* Thread local storage populated in linux_kevent_wait */
        struct epoll_udata    *epoll_udata = ev->data.ptr;
        int                   rv;

        if (!epoll_udata) {
            dbg_puts("event has no knote, skipping..."); /* Forgot to call KN_UDATA()? */
            continue;
        }

        dbg_printf("[%i] %s", i, epoll_event_dump(ev));

        /*
         * epoll event is associated with a single filter
         * so we just have one knote per event.
         *
         * As different filters store pointers to different
         * structures, we need to examine ud_type to figure
         * out what epoll_data contains.
         */
        switch (epoll_udata->ud_type) {
        case EPOLL_UDATA_KNOTE:
        {
            struct knote *kn = epoll_udata->ud_kn;

            assert(kn);
            if (el_p >= el_end) {
            oos:
                dbg_printf("no more available kevent slots, used %zu", el_p - el);
                goto done;
            }

            rv = linux_kevent_copyout_ev(el_p, (el_end - el_p), ev, knote_get_filter(kn), kn);
            if (rv < 0) goto done;
            el_p += rv;
        }
            break;

        /*
         * epoll event is associated with one filter for
         * reading and one filter for writing.
         */
        case EPOLL_UDATA_FD_STATE:
        {
            struct fd_state   *fds = epoll_udata->ud_fds;
            struct knote      *kn, *write;
            assert(fds);

            /*
             * fds can be freed after the first linux_kevent_copyout_ev
             * so cache the pointer value here.
             */
            write = fds->fds_write;

            /*
             *    FD, or errored, or other side shutdown
             */
            if ((kn = fds->fds_read) && (ev->events & (EPOLLIN | EPOLLHUP | EPOLLRDHUP | EPOLLERR))) {
                if (el_p >= el_end) goto oos;

                rv = linux_kevent_copyout_ev(el_p, (el_end - el_p), ev, knote_get_filter(kn), kn);
                if (rv < 0) goto done;
                el_p += rv;
            }

            /*
             *    FD is writable, or errored, or other side shutdown
             */
            if ((kn = write) && (ev->events & (EPOLLOUT | POLLHUP | EPOLLERR))) {
                if (el_p >= el_end) goto oos;

                rv = linux_kevent_copyout_ev(el_p, (el_end - el_p), ev, knote_get_filter(kn), kn);
                if (rv < 0) goto done;
                el_p += rv;
            }
        }
            break;

        case EPOLL_UDATA_EVENT_FD:
        {
            struct eventfd    *efd = epoll_udata->ud_efd;

            assert(efd);

            rv = linux_kevent_copyout_ev(el_p, (el_end - el_p), ev, efd->ef_filt, NULL);
            if (rv < 0) goto done;
            el_p += rv;
            break;
        }

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
linux_eventfd_register(struct kqueue *kq, struct eventfd *efd)
{
    EVENTFD_UDATA(efd); /* setup udata for the efd */

    if (epoll_ctl(kq->epollfd, EPOLL_CTL_ADD, kqops.eventfd_descriptor(efd), EPOLL_EV_EVENTFD(EPOLLIN, efd)) < 0) {
        dbg_perror("epoll_ctl(2) - register epoll_fd=%i eventfd=%i", kq->epollfd, kqops.eventfd_descriptor(efd));
        return (-1);
    }

    return (0);
}

void
linux_eventfd_unregister(struct kqueue *kq, struct eventfd *efd)
{
    if (epoll_ctl(kq->epollfd, EPOLL_CTL_DEL, kqops.eventfd_descriptor(efd), NULL) < 0)
        dbg_perror("epoll_ctl(2) - unregister epoll_fd=%i eventfd=%i", kq->epollfd, kqops.eventfd_descriptor(efd));
}

static int
linux_eventfd_init(struct eventfd *efd, struct filter *filt)
{
    int evfd;

    evfd = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    if (evfd < 0) {
        dbg_perror("eventfd");
        return (-1);
    }
    dbg_printf("eventfd=%i - created", evfd);
    efd->ef_id = evfd;
    efd->ef_filt = filt;

    return (0);
}

static void
linux_eventfd_close(struct eventfd *efd)
{
    dbg_printf("eventfd=%i - closed", efd->ef_id);
    if (close(efd->ef_id) < 0)
        dbg_perror("close(2)");
    efd->ef_id = -1;
}

static int
linux_eventfd_raise(struct eventfd *efd)
{
    uint64_t counter;
    int rv = 0;

    dbg_printf("eventfd=%i - raising event level", efd->ef_id);
    counter = 1;
    if (write(efd->ef_id, &counter, sizeof(counter)) < 0) {
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

static int
linux_eventfd_lower(struct eventfd *efd)
{
    uint64_t cur;
    ssize_t n;
    int rv = 0;

    /*
     * Reset the counter
     * Because we're not using EFD_SEMPAHOR the level
     * state of the eventfd is cleared.
     *
     * Thus if there were multiple calls to
     * linux_eventfd_raise, and a single call to
     * linux_eventfd_lower, the eventfd state would
     * still be lowered.
     */
    dbg_printf("eventfd=%i - lowering event level", efd->ef_id);
    n = read(efd->ef_id, &cur, sizeof(cur));
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

static int
linux_eventfd_descriptor(struct eventfd *efd)
{
    return (efd->ef_id);
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
            dbg_perror("fd=%i unknown fd type, st_mode=0x%x", fd, sb.st_mode & S_IFMT);
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

        case 0: /* seen with eventfd */
            dbg_printf("fd=%i fstat() provided no S_IFMT flags, treating fd as passive socket", fd);
            kn->kn_flags |= KNFL_SOCKET;
            kn->kn_flags |= KNFL_SOCKET_PASSIVE;
            return (0);
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

    state |= (fds->fds_read && (disabled == ((fds->fds_read->kev.flags & (EV_DISABLE | EV_EOF)) != 0))) * EPOLLIN;
    state |= (fds->fds_write && (disabled == ((fds->fds_write->kev.flags & (EV_DISABLE | EV_EOF)) != 0))) * EPOLLOUT;

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
            dbg_printf("fd_state: new fd=%i events=0x%08x (%s)", fd, ev, epoll_flags_dump(ev));

            fds = malloc(sizeof(struct fd_state));
            if (!fds) return (-1);

            *fds = query;
            FDS_UDATA(fds);    /* Prepare for insertion into epoll */
            RB_INSERT(fd_st, &kq->kq_fd_st, fds);

        } else {
        mod:
            dbg_printf("fd_state: mod fd=%i events=0x%08x (%s)", fd, ev, epoll_flags_dump(ev));
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
        dbg_printf("fd_state: mod fd=%i events=0x%08x (%s)", fds->fds_fd, ev, epoll_flags_dump(ev));
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

    if (KNOTE_DISABLED(kn)) dbg_printf("fd=%i kn=%p is disabled", fd, kn);
    if (KNOTE_IS_EOF(kn)) dbg_printf("fd=%i kn=%p is EOF", fd, kn);

    /*
     * Determine the current state of the file descriptor
     * and see if we need to make changes.
     */
    have_ev = epoll_fd_state(&fds, kn, false);            /* ...enabled only */

    dbg_printf("fd=%i have_ev=0x%04x (%s)", fd, have_ev, epoll_flags_dump(have_ev));
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
            dbg_printf("fd=%i disabled_ev=0x%04x (%s)", fd, to_delete, epoll_flags_dump(to_delete));
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
            dbg_printf("fd=%i disabled_ev=0x%04x (%s)", fd, to_delete, epoll_flags_dump(to_delete));
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
               op, epoll_op_dump(op),
               opn, epoll_op_dump(opn),
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
                    dbg_printf("clearing fd=%i fds=%p ev=%s", fd, fds, epoll_flags_dump(kn_ev));
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

const struct kqueue_vtable kqops = {
    .libkqueue_fork     = linux_libkqueue_fork,
    .libkqueue_free     = linux_libkqueue_free,
    .kqueue_init        = linux_kqueue_init,
    .kqueue_free        = linux_kqueue_free,
    .kevent_wait        = linux_kevent_wait,
    .kevent_copyout     = linux_kevent_copyout,
    .eventfd_register   = linux_eventfd_register,
    .eventfd_unregister = linux_eventfd_unregister,
    .eventfd_init       = linux_eventfd_init,
    .eventfd_close      = linux_eventfd_close,
    .eventfd_raise      = linux_eventfd_raise,
    .eventfd_lower      = linux_eventfd_lower,
    .eventfd_descriptor = linux_eventfd_descriptor,
};
