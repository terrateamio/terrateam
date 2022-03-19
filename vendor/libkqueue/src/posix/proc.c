/*
 * Copyright (c) 2021 Arran Cudbard-Bell <a.cudbardb@freeradius.org>
 * Copyright (c) 2009 Mark Heily <mark@heily.com>
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
#include <err.h>
#include <signal.h>
#include <sys/prctl.h>
#include <sys/wait.h>
#include <unistd.h>

#include <limits.h>

#include "../common/private.h"

/** An entry in the proc_pid tree
 *
 * This contains a list of PIDs all kqueues are interested in
 * and a list of knotes that are waiting on notifications for
 * those PIDs.
 */
struct proc_pid {
    RB_ENTRY(proc_pid)            ppd_entry;   //!< Entry in the proc_pid_index tree.
    pid_t                         ppd_pid;     //!< PID we're waiting on.
    LIST_HEAD(pid_waiters, knote) ppd_proc_waiters; //!< knotes that are waiting on this PID.
};

static tracing_mutex_t     proc_init_mtx = TRACING_MUTEX_INITIALIZER;
static int                 proc_count = 0;
static pthread_t           proc_wait_thread_id;

/** The global PID tree
 *
 * Contains all the PIDs any kqueue is interested in waiting on
 */
static RB_HEAD(pid_index, proc_pid) proc_pid_index;
static tracing_mutex_t    proc_pid_index_mtx = TRACING_MUTEX_INITIALIZER;
#ifndef _WIN32
pthread_mutexattr_t       proc_pid_index_mtx_attr;
#endif

static int
proc_pid_cmp(struct proc_pid *a, struct proc_pid *b)
{
    return (a->ppd_pid > b->ppd_pid) - (a->ppd_pid < b->ppd_pid);
}

RB_GENERATE(pid_index, proc_pid, ppd_entry, proc_pid_cmp)

/** Notify all the waiters on a PID
 *
 * @note This must be called with the proc_pid_index_mtx held
 *       to prevent knotes/filters/kqueues being freed out from
 *       beneath us.  When a filter is freed it will attempt
 *       to free all associated knotes, and will attempt to
 *       lock the proc_pid_index_mtx in evfilt_proc_knote_delete.
 *       If we hold this mutex then the deletion cannot proceed.
 */
static void
waiter_notify(struct proc_pid *ppd, int status)
{
    struct knote *kn;
    struct filter *filt;

    while ((kn = LIST_FIRST(&ppd->ppd_proc_waiters))) {
        kn->kn_proc_status = status;

        /*
         * This operates in the context of the kqueue
         * that the knote belongs to.  We may up
         * signalling multiple kqueues that the
         * specified process exited, and for each one
         * we need to call eventfd_raise.
         */
        filt = knote_get_filter(kn);
        dbg_printf("pid=%u exited, notifying kq=%u filter=%p kn=%p",
                   (unsigned int)ppd->ppd_pid, kn->kn_kq->kq_id, filt, kn);
        kqops.eventfd_raise(&filt->kf_proc_eventfd);
        LIST_INSERT_HEAD(&filt->kf_ready, kn, kn_ready); /* protected by proc_pid_index_mtx */

        LIST_REMOVE_ZERO(kn, kn_proc_waiter);
    }

    dbg_printf("pid=%u removing waiter list", (unsigned int)ppd->ppd_pid);
    RB_REMOVE(pid_index, &proc_pid_index, ppd);
    free(ppd);
}

static void
waiter_notify_error(struct proc_pid *ppd, int wait_errno)
{
    struct knote *kn;
    struct filter *filt;

    while ((kn = LIST_FIRST(&ppd->ppd_proc_waiters))) {
        kn->kev.flags |= EV_ERROR;
        kn->kev.data = wait_errno;

        filt = knote_get_filter(kn);
        dbg_printf("pid=%u errored (%s), notifying kq=%u filter=%p kn=%p",
                   (unsigned int)ppd->ppd_pid, strerror(errno), kn->kn_kq->kq_id, filt, kn);
        kqops.eventfd_raise(&filt->kf_proc_eventfd);
        LIST_INSERT_HEAD(&filt->kf_ready, kn, kn_ready); /* protected by proc_pid_index_mtx */

        LIST_REMOVE_ZERO(kn, kn_proc_waiter);
    }

    dbg_printf("pid=%u removing waiter list", (unsigned int)ppd->ppd_pid);
    RB_REMOVE(pid_index, &proc_pid_index, ppd);
    free(ppd);
}

static int
waiter_siginfo_to_status(siginfo_t *info)
{
    int status = 0;

    /*
     *  Try and reconstruct the status code that would have been
     *  returned by waitpid.  The OpenBSD man pages
     *  and observations of the macOS kqueue confirm this is what
     *  we should be returning in the data field of the kevent.
     */
    switch (info->si_code) {
    case CLD_EXITED:    /* WIFEXITED - High byte contains status, low byte zeroed */
    status = info->si_status << 8;
        dbg_printf("pid=%u exited, status %u", (unsigned int)info->si_pid, status);
        break;

    case CLD_DUMPED:    /* WIFSIGNALED/WCOREDUMP - Core flag set - Low 7 bits contains fatal signal */
        status |= 0x80; /* core flag */
        status = info->si_status & 0x7f;
        dbg_printf("pid=%u dumped, status %u", (unsigned int)info->si_pid, status);
        break;

    case CLD_KILLED:    /* WIFSIGNALED - Low 7 bits contains fatal signal */
        status = info->si_status & 0x7f;
        dbg_printf("pid=%u signalled, status %u", (unsigned int)info->si_pid, status);
        break;

    default: /* The rest aren't valid exit states */
        status = -1;
    }

    return status;
}

/** This waiter thread serves all kqueues in a given process
 *
 */
static void *
wait_thread(UNUSED void *arg)
{
    int status;
    int ret = 0;
    siginfo_t info;
    sigset_t sigmask;
    struct proc_pid *ppd, *ppd_tmp;

    /* Set the thread's name to something descriptive so it shows up in gdb,
     * etc. Max name length is 16 bytes. */
    prctl(PR_SET_NAME, "libkqueue_wait", 0, 0, 0);

    dbg_printf("waiter thread started");

    /*
     * Native kqueue implementations leave processes monitored
     * with EVFILT_PROC + NOTE_EXIT un-reaped when they exit.
     *
     * Applications using kqueue expect to be able to retrieve
     * the process exit state using one of the *wait*() calls.
     *
     * So that these applications don't experience errors,
     * processes must remain un-reaped so those subsequent
     * *wait*() calls can succeed.
     *
     * Because processes must remain un-reaped we can only use
     * calls which accept the WNOWAIT flag, and do not reap
     * processes.
     *
     * The obvious solution is to use waitid(P_ALL,,,WNOWAIT),
     * and only notify on the PIDs we're interested in.
     * Unfortunately waitid() will return the same PID repeatedly
     * if the previously returned PID was not reaped.
     *
     * At first glance sigwaitinfo([SIGCHLD], ) appears to be
     * another promising option.  The siginfo_t populated by
     * sigwaitinfo() contains all the information we need to
     * raise a notification that a process has exited, and a
     * SIGCHLD signal is raised every time a process exits.
     *
     * Unfortunately on Linux, SIGCHLD signals, along with all
     * other signals, are coalesced.  This means if two children
     * exited before the wait thread was woken up from waiting
     * on sigwaitinfo(), we'd only get the siginfo_t structure
     * populated for one child.
     *
     * The only apparent fully kqueue compatible and POSIX
     * compatible solution is to use sigwatinfo() to determine
     * that _A_ child had exited, and then scan all PIDs we're
     * interested in, passing them to waitid() in turn.
     *
     * This isn't a great solution for the following reasons:
     *
     * - SIGCHLD must be delivered to the wait thread in order
     *   for notifications to be sent out.
     *   If the application installs its own signal handler
     *   for SIGCHLD, or changes the process signal mask,
     *   we may never get notified when a child exits.
     *
     * - Scanning through all the monitored PIDs doesn't scale
     *   well, and involves many system calls.
     *
     * - Because only one thread can receive the SIGCHLD
     *   signal, all monitoring must be done in a single
     *   waiter thread.  This introduces code complexity and
     *   contention around the global tree that holds the PIDs
     *   that are being monitored.
     *
     * Because of these limitations, on Linux >= 5.3 we use
     * pidfd_open() to get a FD bound to a PID that we can
     * monitor.  Testing shows that multiple pidfds bound to
     * the same PID will each receive a notification when
     * that process exits.  Using pidfd avoids the messiness
     * of signals, the linear scans, and the global structures.
     *
     * Unfortunately at the time of writing Linux 5.3 is still
     * relatively new, and the feasibility of writing native
     * solutions for platforms like Solaris hasn't been
     * investigated.
     *
     * Until Linux 5.3 becomes more widely used, and we have
     * a native solution for Solaris this POSIX EVFILT_PROC
     * code must remain to provide a fallback mechanism.
     */

    /*
     * Block all signals - sigwaitinfo isn't affected by this
     */
    sigfillset(&sigmask);
    pthread_sigmask(SIG_BLOCK, &sigmask, NULL);

    /*
     * Only listen on SIGCHLD wait sigwaitinfo
     */
    sigemptyset(&sigmask);
    sigaddset(&sigmask, SIGCHLD);
    do {
        if (ret < 0) {
            dbg_printf("sigwaitinfo(2): %s", strerror(errno));
            continue;
        }

        /*
         * The knote_* functions (i.e. those that could free a
         * knote).
         *
         * All attempt to take this lock before modifying the
         * knotes, wo we shouldn't have any issues here with
         * knotes being freed out from underneath the waiter
         * thread.
         */
        tracing_mutex_lock(&proc_pid_index_mtx);

        /*
         * Sig 0 is the NULL signal.  This means it's the first
         * iteration through the loop, and we just want to scan
         * any existing PIDs.
         *
         * This fixes a potential race between the thread
         * starting, EVFILT_PROC kevents being added, and a
         * process exiting.
         */
        if (ret > 0) {
            /*
             * Check if this is a process we want to monitor
             */
            ppd = RB_FIND(pid_index, &proc_pid_index, &(struct proc_pid){ .ppd_pid = info.si_pid });
            if (ppd) {
                status = waiter_siginfo_to_status(&info);
                if (status >= 0) waiter_notify(ppd, status);  /* If < 0 notification is spurious */
            }
        }

        /*
         * Scan the list of outstanding PIDs to see if
         * there are any we need to notify.
         */
        RB_FOREACH_SAFE(ppd, pid_index, &proc_pid_index, ppd_tmp) {
        again:
            if (waitid(P_PID, ppd->ppd_pid, &info, WEXITED | WNOWAIT | WNOHANG) < 0) {
                switch (errno) {
                case ECHILD:
                    dbg_printf("waitid(2): pid=%u reaped too early - %s", ppd->ppd_pid, strerror(errno));

                    waiter_notify_error(ppd, errno);

                    tracing_mutex_unlock(&proc_pid_index_mtx);

                    continue;

                case EINTR:
                    goto again;
                }
            }

            status = waiter_siginfo_to_status(&info);
            if (status >= 0) waiter_notify(ppd, status);  /* If < 0 notification is spurious */
        }
        tracing_mutex_unlock(&proc_pid_index_mtx);

        dbg_printf("waiting for SIGCHLD");
    } while ((ret = sigwaitinfo(&sigmask, &info)));

    dbg_printf("exited");

    return (NULL);
}

static void
evfilt_proc_libkqueue_init(void)
{
    /*
     * Initialise the global PID index tree.  This needs to be
     * recursive as the delete/enable/disable functions all
     * need to lock the mutex, and they may be called indirectly
     * in the copyout function (which already locks this mutex),
     * as well as by other kqueue code.
     */
#ifndef _WIN32
     pthread_mutexattr_init(&proc_pid_index_mtx_attr);
     pthread_mutexattr_settype(&proc_pid_index_mtx_attr, PTHREAD_MUTEX_RECURSIVE);
#endif
     tracing_mutex_init(&proc_pid_index_mtx, &proc_pid_index_mtx_attr);
}
static int
evfilt_proc_init(struct filter *filt)
{
    if (kqops.eventfd_init(&filt->kf_proc_eventfd, filt) < 0) {
    error_0:
        return (-1);
    }

    if (kqops.eventfd_register(filt->kf_kqueue, &filt->kf_proc_eventfd) < 0) {
    error_1:
        kqops.eventfd_close(&filt->kf_proc_eventfd);
        goto error_0;
    }

    /*
     * Initialise global resources (wait thread and PID tree).
     */
    tracing_mutex_lock(&proc_init_mtx);

    if (proc_count == 0) {
        sigset_t sigmask;

        /*
         * We do this at a process level to ensure
         * that the wait thread is the only thing
         * that receives SIGCHLD.
         *
         * The wait thread will not reliably receive
         * a SIGCHLD signal if SIGCHLD is not
         * blocked in all other threads.
         */
        sigemptyset(&sigmask);
        sigaddset(&sigmask, SIGCHLD);
        pthread_sigmask(SIG_BLOCK, &sigmask, NULL);

        dbg_printf("creating wait thread");

        if (pthread_create(&proc_wait_thread_id, NULL, wait_thread, NULL) != 0) {
            tracing_mutex_unlock(&proc_init_mtx);
            goto error_1;
        }
    }
    proc_count++;
    tracing_mutex_unlock(&proc_init_mtx);

    return (0);
}

static void
evfilt_proc_destroy(struct filter *filt)
{
    /*
     * Free global resources like the wait thread
     * and PID tree.
     */
    tracing_mutex_lock(&proc_init_mtx);
    assert(proc_count > 0);
    if (--proc_count == 0) {
        pthread_cancel(proc_wait_thread_id);
        if (pthread_join(proc_wait_thread_id, NULL) < 0) {
            dbg_printf("pthread_join(2) %s", strerror(errno));
        } else {
            dbg_puts("waiter thread joined");
        }
    }
    tracing_mutex_unlock(&proc_init_mtx);

    kqops.eventfd_unregister(filt->kf_kqueue, &filt->kf_proc_eventfd);
    kqops.eventfd_close(&filt->kf_proc_eventfd);
}

static int
evfilt_proc_knote_create(struct filter *filt, struct knote *kn)
{
    struct proc_pid *ppd;

    tracing_mutex_lock(&proc_pid_index_mtx);
    /*
     * Fixme - We should probably check to see if the PID exists
     * here and error out early instead of waiting for the waiter
     * loop to tell us.
     */

    ppd = RB_FIND(pid_index, &proc_pid_index, &(struct proc_pid){ .ppd_pid = kn->kev.ident });
    if (!ppd) {
        dbg_printf("pid=%u adding waiter list", (unsigned int)kn->kev.ident);
        ppd = calloc(1, sizeof(struct proc_pid));
        if (unlikely(!ppd)) {
            tracing_mutex_unlock(&proc_pid_index_mtx);
            return -1;
        }
        ppd->ppd_pid = kn->kev.ident;
        RB_INSERT(pid_index, &proc_pid_index, ppd);
    }
    LIST_INSERT_HEAD(&ppd->ppd_proc_waiters, kn, kn_proc_waiter);
    tracing_mutex_unlock(&proc_pid_index_mtx);

    /*
     * These get added by default on macOS (and likely FreeBSD)
     * which make sense considering a process exiting is an
     * edge triggered event, not a level triggered one.
     */
    kn->kev.flags |= EV_ONESHOT;
    kn->kev.flags |= EV_CLEAR;

    return (0);
}

int
evfilt_proc_knote_modify(UNUSED struct filter *filt, UNUSED struct knote *kn,
        UNUSED const struct kevent *kev)
{
    return (0); /* All work done in common code */
}

int
evfilt_proc_knote_delete(UNUSED struct filter *filt, struct knote *kn)
{
    struct proc_pid *ppd;

    tracing_mutex_lock(&proc_pid_index_mtx);
    if (LIST_INSERTED(kn, kn_proc_waiter)) LIST_REMOVE_ZERO(kn, kn_proc_waiter);

    /*
     * ppd may have been removed already if there
     * were no more waiters.
     */
    ppd = RB_FIND(pid_index, &proc_pid_index, &(struct proc_pid){ .ppd_pid = kn->kev.ident });
    if (ppd) {
        if (LIST_EMPTY(&ppd->ppd_proc_waiters)) {
            dbg_printf("pid=%u removing waiter list", (unsigned int)ppd->ppd_pid);
            RB_REMOVE(pid_index, &proc_pid_index, ppd);
            free(ppd);
        } else {
             dbg_printf("pid=%u leaving waiter list", (unsigned int)ppd->ppd_pid);
        }
    } else {
        dbg_printf("pid=%u waiter list already removed", (unsigned int)kn->kev.ident);
    }
    tracing_mutex_unlock(&proc_pid_index_mtx);

    return (0);
}

int
evfilt_proc_knote_disable(UNUSED struct filter *filt, struct knote *kn)
{
    /*
     * Remove the knote from the waiter list but
     * don't free the waiter list itself.
     *
     * If two knotes are waiting on a PID and one
     * is disabled and the other is deleted,
     * then the `struct proc_pid` will be freed,
     * which is why we need to run the same logic
     * as knote_create when re-enabling.
     */
    tracing_mutex_lock(&proc_pid_index_mtx);
    if (LIST_INSERTED(kn, kn_proc_waiter)) LIST_REMOVE_ZERO(kn, kn_proc_waiter);
    tracing_mutex_unlock(&proc_pid_index_mtx);

    return (0);
}

static int
evfilt_proc_knote_copyout(struct kevent *dst, int nevents, struct filter *filt,
    struct knote *kn, void *ev)
{
    struct kevent *dst_p = dst, *dst_end = dst_p + nevents;

    /*
     * Prevent the waiter thread from modifying
     * the knotes in the ready list whilst we're
     * processing them.
     *
     * At first glance this wouldn't appear to
     * require a global lock.  The issue is that
     * if we use filter-specific locks to protect
     * the kf_ready list, we can get into a deadlock
     * where the waiter thread holds the lock on
     * proc_pid_index_mtx, and it attempting to lock
     * the filter lock to insert new ready
     * notifications, and we're holding the filter
     * lock, and attempting to delete a knote,
     * which requires holding the proc_pid_index_mtx.
     *
     * This was seen in the real world and caused
     * major issues.
     *
     * By using a single lock we ensure either the
     * waiter thread is notifying kqueue isntances
     * data is ready, or a kqueue is copying out
     * notifications, so no deadlock can occur.
     */
    tracing_mutex_lock(&proc_pid_index_mtx);
    assert(!LIST_EMPTY(&filt->kf_ready));

    /*
     * kn arg is always NULL here, so we just reuse it
     * for the loop.
     */
    while ((kn = LIST_FIRST(&filt->kf_ready))) {
        if (dst_p >= dst_end)
            break;

        kevent_dump(&kn->kev);
        memcpy(dst_p, &kn->kev, sizeof(*dst));
        dst_p->fflags = NOTE_EXIT;
        dst_p->flags |= EV_EOF;
        dst_p->data = kn->kn_proc_status;

        LIST_REMOVE_ZERO(kn, kn_ready); /* knote_copyout_flag_actions may free the knote */

        if (knote_copyout_flag_actions(filt, kn) < 0) {
            LIST_INSERT_HEAD(&filt->kf_ready, kn, kn_ready);
            tracing_mutex_unlock(&proc_pid_index_mtx);
            return -1;
        }

        dst_p++;
    }

    if (LIST_EMPTY(&filt->kf_ready))
        kqops.eventfd_lower(&filt->kf_proc_eventfd);
    tracing_mutex_unlock(&proc_pid_index_mtx);

    return (dst_p - dst);
}

const struct filter evfilt_proc = {
    .libkqueue_init   = evfilt_proc_libkqueue_init,
    .kf_id            = EVFILT_PROC,
    .kf_init          = evfilt_proc_init,
    .kf_destroy       = evfilt_proc_destroy,
    .kf_copyout       = evfilt_proc_knote_copyout,
    .kn_create        = evfilt_proc_knote_create,
    .kn_modify        = evfilt_proc_knote_modify,
    .kn_enable        = evfilt_proc_knote_create,
    .kn_disable       = evfilt_proc_knote_disable,
    .kn_delete        = evfilt_proc_knote_delete
};
