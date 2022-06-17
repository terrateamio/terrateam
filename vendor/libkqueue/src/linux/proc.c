/*
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
#include "private.h"

/* We depend on the SYS_pidfd_open call to determine when a process has exited
 *
 * The SYS_pidfd_open call is only available in Kernels >= 5.3.  If this call
 * isn't available there's currently no good fallback.
 *
 * If the build system detects SYS_pidfd_open is not available it will fall back
 * to using posix/proc.c and won't build this source file.
 */
#include <sys/syscall.h>
#include <sys/wait.h>

int
evfilt_proc_copyout(struct kevent *dst, UNUSED int nevents, struct filter *filt,
    struct knote *src, UNUSED_NDEBUG void *ptr)
{
    siginfo_t info;
    unsigned int status = 0;
#ifndef NDEBUG
    struct epoll_event * const ev = (struct epoll_event *) ptr;
#endif

    dbg_printf("epoll_ev=%s", epoll_event_dump(ev));
    memcpy(dst, &src->kev, sizeof(*dst)); /* Populate flags from the src kevent */

    /* Get the exit status _without_ reaping the process, waitpid() should still work in the caller */
    if (waitid(P_PID, (id_t)src->kev.ident, &info, WEXITED | WNOHANG | WNOWAIT) < 0) {
        dbg_printf("waitid(2): %s", strerror(errno));
        return (-1);
    }

    /*
     *  Try and reconstruct the status code that would have been
     *  returned by waitpid.  The OpenBSD man pages
     *  and observations of the macOS kqueue confirm this is what
     *  we should be returning in the data field of the kevent.
     */
    switch (info.si_code) {
    case CLD_EXITED:    /* WIFEXITED - High byte contains status, low byte zeroed */
        status = info.si_status << 8;
        dbg_printf("pid=%u exited, status %u", (unsigned int)src->kev.ident, status);
        break;

    case CLD_DUMPED:    /* WIFSIGNALED/WCOREDUMP - Core flag set - Low 7 bits contains fatal signal */
        status |= 0x80; /* core flag */
        status |= info.si_status & 0x7f;
        dbg_printf("pid=%u dumped, status %u", (unsigned int)src->kev.ident, status);
        break;

    case CLD_KILLED:    /* WIFSIGNALED - Low 7 bits contains fatal signal */
        status = info.si_status & 0x7f;
        dbg_printf("pid=%u signalled, status %u", (unsigned int)src->kev.ident, status);
        break;

    default: /* The rest aren't valid exit states */
        return (0);
    }

    dst->data = status;
    dst->flags |= EV_EOF; /* Set in macOS and FreeBSD kqueue implementations */

    if (knote_copyout_flag_actions(filt, src) < 0) return -1;

    return (1);
}

int
evfilt_proc_knote_enable(struct filter *filt, struct knote *kn)
{
    if (epoll_ctl(filter_epoll_fd(filt), EPOLL_CTL_ADD, kn->kn_procfd, EPOLL_EV_KN(EPOLLIN, kn)) < 0) {
        dbg_printf("epoll_ctl(2): %s", strerror(errno));
        return -1;
    }
    return (0);
}

int
evfilt_proc_knote_disable(struct filter *filt, struct knote *kn)
{
    if (epoll_ctl(filter_epoll_fd(filt), EPOLL_CTL_DEL, kn->kn_procfd, NULL) < 0) {
        dbg_printf("epoll_ctl(2): %s", strerror(errno));
        return (-1);
    }
    return (0);
}

int
evfilt_proc_knote_create(struct filter *filt, struct knote *kn)
{
    int pfd;

    /* This mirrors the behaviour of kqueue if fflags doesn't specify any events */
    if (!(kn->kev.fflags & NOTE_EXIT)) {
        dbg_printf("not monitoring pid=%u as no NOTE_* fflags set", (unsigned int)kn->kev.ident);
        kn->kn_procfd = -1;
        return 0;
    }

    /* Returns an FD, which, when readable, indicates the process has exited */
    pfd = syscall(SYS_pidfd_open, (pid_t)kn->kev.ident, 0);
    if (pfd < 0) {
        dbg_perror("pidfd_open(2)");
        return (-1);
    }
    if (fcntl(pfd, F_SETFD, FD_CLOEXEC) < 0) {
        dbg_perror("fcntl(2)");
        return (-1);
    }
    dbg_printf("created pidfd=%i monitoring pid=%u", pfd, (unsigned int)kn->kev.ident);

    kn->kn_procfd = pfd;

    /*
     * These get added by default on macOS (and likely FreeBSD)
     * which make sense considering a process exiting is an
     * edge triggered event, not a level triggered one.
     */
    kn->kev.flags |= EV_ONESHOT;
    kn->kev.flags |= EV_CLEAR;

    KN_UDATA(kn);   /* populate this knote's kn_udata field */

    return evfilt_proc_knote_enable(filt, kn);
}

int
evfilt_proc_knote_modify(struct filter *filt, struct knote *kn, const struct kevent *kev)
{
    /* We don't need to make any changes to the pidfd, just record the new flags */
    kn->kev.flags = kev->flags;
    kn->kev.fflags = kev->fflags;

    if (kn->kn_procfd < 0) return evfilt_proc_knote_create(filt, kn);

    return (0);
}

int
evfilt_proc_knote_delete(struct filter *filt, struct knote *kn)
{
    int rv = 0;

    /* If it's enabled, we need to remove the pidfd from epoll */
    if (KNOTE_ENABLED(kn) && (evfilt_proc_knote_disable(filt, kn) < 0)) rv = -1;

    dbg_printf("closed pidfd=%i", kn->kn_procfd);
    if (close(kn->kn_procfd) < 0) rv = -1;
    kn->kn_procfd = -1;

    return (rv);
}

const struct filter evfilt_proc = {
    .kf_id      = EVFILT_PROC,
    .kf_copyout = evfilt_proc_copyout,
    .kn_create  = evfilt_proc_knote_create,
    .kn_modify  = evfilt_proc_knote_modify,
    .kn_delete  = evfilt_proc_knote_delete,
    .kn_enable  = evfilt_proc_knote_enable,
    .kn_disable = evfilt_proc_knote_disable,
};
