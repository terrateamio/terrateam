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
#include <err.h>
#include <signal.h>
#include <sys/prctl.h>
#include <sys/wait.h>
#include <unistd.h>

#include <limits.h>

#include "private.h"

pthread_cond_t   wait_cond = PTHREAD_COND_INITIALIZER;
pthread_mutex_t  wait_mtx = PTHREAD_MUTEX_INITIALIZER;

struct evfilt_data {
    pthread_t       wthr_id;
};

static void *
wait_thread(void *arg)
{
    struct filter *filt = (struct filter *) arg;
    struct knote *dst;
    int status;
    siginfo_t info;
    pid_t pid;
    sigset_t sigmask;

    /* Block all signals */
    sigfillset (&sigmask);
    sigdelset(&sigmask, SIGCHLD);
    pthread_sigmask(SIG_BLOCK, &sigmask, NULL);

    for (;;) {
        /* Get the exit status _without_ reaping the process, waitpid() should still work in the caller */
        if (waitid(P_ALL, 0, &info, WEXITED | WNOWAIT) < 0) {
            if (errno == ECHILD) {
                dbg_puts("got ECHILD, waiting for wakeup condition");
                pthread_mutex_lock(&wait_mtx);
                pthread_cond_wait(&wait_cond, &wait_mtx);
                pthread_mutex_unlock(&wait_mtx);
                dbg_puts("awoken from ECHILD-induced sleep");
                continue;
            }
            if (errno == EINTR)
                continue;
            dbg_printf("waitid(2): %s", strerror(errno));
        }

        /* Scan the wait queue to see if anyone is interested */
        pthread_mutex_lock(&filt->kf_mtx);
        dst = knote_lookup(filt, pid);
        if (!dst)
            goto next;

        /*
         *  Try and reconstruct the status code that would have been
         *  returned by waitpid.  The OpenBSD man pages
         *  and observations of the macOS kqueue confirm this is what
         *  we should be returning in the data field of the kevent.
         */
        switch (info.si_code) {
        case CLD_EXITED:    /* WIFEXITED - High byte contains status, low byte zeroed */
        status = info.si_status << 8;
            dbg_printf("pid=%u exited, status %u", (unsigned int)info.si_pid, status);
            break;

        case CLD_DUMPED:    /* WIFSIGNALED/WCOREDUMP - Core flag set - Low 7 bits contains fatal signal */
            status |= 0x80; /* core flag */
            status = info.si_status & 0x7f;
            dbg_printf("pid=%u dumped, status %u", (unsigned int)info.si_pid, status);
            break;

        case CLD_KILLED:    /* WIFSIGNALED - Low 7 bits contains fatal signal */
            status = info.si_status & 0x7f;
            dbg_printf("pid=%u signalled, status %u", (unsigned int)info.si_pid, status);
            break;

        default: /* The rest aren't valid exit states */
            goto next;
        }

        dst->kev.data = status;
        dst->flags |= EV_EOF; /* Set in macOS and FreeBSD kqueue implementations */

        LIST_REMOVE(dst, kn_list);
        LIST_INSERT_HEAD(&filt->kf_eventlist, kn, kn_list);
        filter_raise(filt);

    next:
        pthread_mutex_unlock(&filt->kf_mtx);
    }

    /* TODO: error handling */

    return (NULL);
}

static int
evfilt_proc_init(struct filter *filt)
{
    struct evfilt_data *ed;

    if ((ed = calloc(1, sizeof(*ed))) == NULL)
        return (-1);

    if (filter_socketpair(filt) < 0)
        goto errout;
    if (pthread_create(&ed->wthr_id, NULL, wait_thread, filt) != 0)
        goto errout;

    /* Set the thread's name to something descriptive so it shows up in gdb,
     * etc. Max name length is 16 bytes. */
    prctl(PR_SET_NAME, "libkqueue_wait", 0, 0, 0);

    return (0);

errout:
    free(ed);
    return (-1);
}

static void
evfilt_proc_destroy(struct filter *filt)
{
    pthread_cancel(filt->kf_data->wthr_id);
    close(filt->kf_pfd);
}

static int
evfilt_proc_create(struct filter *filt,
        struct knote *dst, const struct kevent *src)
{
    if (src->flags & EV_ADD && KNOTE_EMPTY(dst)) {
        memcpy(&dst->kev, src, sizeof(*src));
        /* TODO: think about locking the mutex first.. */
        pthread_cond_signal(&wait_cond);
    }

    if (src->flags & EV_ADD || src->flags & EV_ENABLE) {
        /* Nothing to do.. */
    }

    return (0);
}

static int
evfilt_proc_copyout(struct kevent *dst, int nevents, struct filter *filt,
    struct knote *kn, void *ev)
{
    struct knote *kn;
    int events = 0;

    LIST_FOREACH_SAFE(kn, &filt->kf_eventlist, kn_list) {
        if (++events > nevents)
            break;

        kevent_dump(&kn->kev);
        memcpy(dst, &kn->kev, sizeof(*dst));
        dst->fflags = NOTE_EXIT;


        if (knote_copyout_flag_actions(filt, kn) < 0) return -1;

        dst++;
    }

    if (!LIST_EMPTY(&filt->kf_eventlist))
        filter_raise(filt);

    return (nevents);
}

const struct filter evfilt_proc = {
    .kf_id      = EVFILT_PROC,
    .kf_init    = evfilt_proc_init,
    .kf_destroy = evfilt_proc_destroy,
    .kf_copyout = evfilt_proc_copyout,
    .kn_create  = evfilt_proc_create,
};
