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

static pthread_mutex_t     proc_init_mtx = PTHREAD_MUTEX_INITIALIZER;
static unsigned int        proc_count = 0;
static pthread_t           proc_wait_thread_id;

/** The global PID tree
 *
 * Contains all the PIDs any kqueue is interested in waiting on
 */
static RB_HEAD(pid_index, proc_pid) proc_pid_index;
static pthread_mutex_t              proc_pid_index_mtx = PTHREAD_MUTEX_INITIALIZER;


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
        pthread_mutex_lock(&filt->kf_knote_mtx);
        kqops.eventfd_raise(&filt->kf_proc_eventfd);
        LIST_INSERT_HEAD(&filt->kf_ready, kn, kn_ready);
        pthread_mutex_unlock(&filt->kf_knote_mtx);

        LIST_REMOVE(kn, kn_proc_waiter);
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
    int ret;
    siginfo_t info;
    sigset_t sigmask;
    struct proc_pid *ppd, *ppd_tmp;

    /* Block all signals except SIGCHLD */
    sigfillset(&sigmask);
    sigdelset(&sigmask, SIGCHLD);
    pthread_sigmask(SIG_BLOCK, &sigmask, NULL);

    /* Set the thread's name to something descriptive so it shows up in gdb,
     * etc. Max name length is 16 bytes. */
    prctl(PR_SET_NAME, "libkqueue_wait", 0, 0, 0);

    /*
     * Only listen on SIGCHLD
     */
    sigemptyset(&sigmask);
    sigaddset(&sigmask, SIGCHLD);
    pthread_sigmask(SIG_UNBLOCK, &sigmask, NULL);

    dbg_printf("started and waiting for SIGCHLD");

    /*
     * To avoid messing up the application linked to libkqueue
     * and reaping all child processes we must use WNOWAIT in
     * any *wait*() calls.  Even for PIDs registered with the
     * EV_PROC filter we're not meant to reap the process because
     * we're trying to behave identically to BSD kqueue and BSD
     * kqueue doesn't do this.
     *
     * Unfortunately waitid() will return the same PID repeatedly
     * if passed P_ALL/WNOWAIT if the previously returned PID
     * is not reaped.
     *
     * We can use SIGCHLD to get notified when a child process
     * exits.  Unfortunately Linux (in particular) will coalesce
     * multiple signals sent to the same process, so we can't
     * rely on sigwaitinfo alone.
     *
     * The final solution is to use sigwaitinfo() as a
     * notification that a child exited, and then scan through
     * the list of PIDs we're waiting on using waitid to see if
     * any of those exited.
     */
    while ((ret = sigwaitinfo(&sigmask, &info))) {
        if (ret < 0) {
            dbg_printf("sigwaitinfo(2): %s", strerror(errno));
            continue;
        }

        dbg_printf("received SIGCHLD");

        pthread_mutex_lock(&proc_pid_index_mtx);
        /*
         * Check if this is a process we want to monitor
         */
        ppd = RB_FIND(pid_index, &proc_pid_index, &(struct proc_pid){ .ppd_pid = info.si_pid });
        if (ppd) {
            status = waiter_siginfo_to_status(&info);
            if (status >= 0) waiter_notify(ppd, status);  /* If < 0 notification is spurious */
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
                    continue; /* FIXME - Maybe produce an EV_ERROR for each of the knotes? */

                case EINTR:
                    goto again;
                }
            }

            status = waiter_siginfo_to_status(&info);
            if (status >= 0) waiter_notify(ppd, status);  /* If < 0 notification is spurious */
        }
        pthread_mutex_unlock(&proc_pid_index_mtx);
    }

    dbg_printf("exited");

    return (NULL);
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
    pthread_mutex_lock(&proc_init_mtx);
    if (proc_count == 0) {
        sigset_t sigmask;

        /*
         * We do this at a process level to ensure
         * that the wait thread is the only thing
         * that receives SIGCHLD.
         *
         * The wait thread does not receive the
         * SIGCHLD without this code.
         */
        sigemptyset(&sigmask);
        sigaddset(&sigmask, SIGCHLD);
        pthread_sigmask(SIG_BLOCK, &sigmask, NULL);

        dbg_printf("creating wait thread");

        if (pthread_create(&proc_wait_thread_id, NULL, wait_thread, NULL) != 0) {
            pthread_mutex_unlock(&proc_init_mtx);
            goto error_1;
        }
        proc_count++;
    }
    pthread_mutex_unlock(&proc_init_mtx);

    return (0);
}

static void
evfilt_proc_destroy(struct filter *filt)
{
    /*
     * Free global resources like the wait thread
     * and PID tree.
     */
    pthread_mutex_lock(&proc_init_mtx);
    if (--proc_count == 0) {
        pthread_cancel(proc_wait_thread_id);
    }
    pthread_mutex_unlock(&proc_init_mtx);

    kqops.eventfd_unregister(filt->kf_kqueue, &filt->kf_proc_eventfd);
    kqops.eventfd_close(&filt->kf_proc_eventfd);
}

static int
evfilt_proc_knote_create(struct filter *filt, struct knote *kn)
{
    struct proc_pid *ppd;

    pthread_mutex_lock(&proc_pid_index_mtx);
    ppd = RB_FIND(pid_index, &proc_pid_index, &(struct proc_pid){ .ppd_pid = kn->kev.ident });
    if (!ppd) {
        dbg_printf("pid=%u adding waiter list", (unsigned int)kn->kev.ident);
        ppd = calloc(1, sizeof(struct proc_pid));
        if (unlikely(!ppd)) {
            pthread_mutex_unlock(&proc_pid_index_mtx);
            return -1;
        }
        ppd->ppd_pid = kn->kev.ident;
        RB_INSERT(pid_index, &proc_pid_index, ppd);
    }
    LIST_INSERT_HEAD(&ppd->ppd_proc_waiters, kn, kn_proc_waiter);
    pthread_mutex_unlock(&proc_pid_index_mtx);

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

    pthread_mutex_lock(&proc_pid_index_mtx);
    if (LIST_INSERTED(kn, kn_proc_waiter)) LIST_REMOVE(kn, kn_proc_waiter);

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
    pthread_mutex_unlock(&proc_pid_index_mtx);

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
     * as on create when re-enabling.
     */
    pthread_mutex_lock(&proc_pid_index_mtx);
    if (LIST_INSERTED(kn, kn_proc_waiter)) LIST_REMOVE(kn, kn_proc_waiter);
    pthread_mutex_unlock(&proc_pid_index_mtx);

    return (0);
}

static int
evfilt_proc_knote_copyout(struct kevent *dst, int nevents, struct filter *filt,
    struct knote *kn, void *ev)
{
    struct knote *tmp;
    int events = 0;

    /*
     * Prevent the waiter thread from modifying
     * the knotes in the ready list whilst we're
     * processing them.
     */
    pthread_mutex_lock(&filt->kf_knote_mtx);

    /*
     * kn arg is always NULL here, so we just reuse it
     * for the loop.
     */
    LIST_FOREACH_SAFE(kn, &filt->kf_ready, kn_ready, tmp) {
        if (++events > nevents)
            break;

        kevent_dump(&kn->kev);
        memcpy(dst, &kn->kev, sizeof(*dst));
        dst->fflags = NOTE_EXIT;
        dst->flags |= EV_EOF;
        dst->data = kn->kn_proc_status;

        if (knote_copyout_flag_actions(filt, kn) < 0) return -1;

        dst++;
    }
    if (LIST_EMPTY(&filt->kf_ready))
        kqops.eventfd_lower(&filt->kf_proc_eventfd);
    pthread_mutex_unlock(&filt->kf_knote_mtx);

    return (nevents);
}

const struct filter evfilt_proc = {
    .kf_id      = EVFILT_PROC,
    .kf_init    = evfilt_proc_init,
    .kf_destroy = evfilt_proc_destroy,
    .kf_copyout = evfilt_proc_knote_copyout,
    .kn_create  = evfilt_proc_knote_create,
    .kn_modify  = evfilt_proc_knote_modify,
    .kn_enable  = evfilt_proc_knote_create,
    .kn_disable = evfilt_proc_knote_disable,
    .kn_delete  = evfilt_proc_knote_delete
};
