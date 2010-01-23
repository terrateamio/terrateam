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

#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/queue.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <string.h>
#include <unistd.h>

#include <sys/signalfd.h>

#include "sys/event.h"
#include "private.h"

/* Highest signal number supported. POSIX standard signals are < 32 */
#define SIGNAL_MAX      32

static int
update_sigmask(const struct filter *filt)
{
    int rv;
    rv = signalfd(filt->kf_pfd, &filt->kf_sigmask, 0);
    dbg_printf("signalfd = %d", filt->kf_pfd);
    if (rv < 0 || rv != filt->kf_pfd) {
        dbg_printf("signalfd(2): %s", strerror(errno));
        return (-1);
    }

    return (0);
}

int
evfilt_signal_init(struct filter *filt)
{
    sigemptyset(&filt->kf_sigmask);
    filt->kf_pfd = signalfd(-1, &filt->kf_sigmask, 0);
    dbg_printf("signalfd = %d", filt->kf_pfd);
    if (filt->kf_pfd < 0) 
        return (-1);

    return (0);
}

void
evfilt_signal_destroy(struct filter *filt)
{
    close (filt->kf_pfd);
}

int
evfilt_signal_copyout(struct filter *filt, 
            struct kevent *dst, 
            int nevents)
{
    struct knote *kn;
    struct signalfd_siginfo sig[MAX_KEVENT];
    int i;
    ssize_t n;

    n = read(filt->kf_pfd, &sig, nevents * sizeof(sig[0]));
    if (n < 0 || n < sizeof(sig[0])) {
        dbg_puts("invalid read from signalfd");
        return (-1);
    }
    n /= sizeof(sig[0]);

    for (i = 0, nevents = 0; i < n; i++) {
        /* This is not an error because of this race condition:
         *    1. Signal arrives and is queued
         *    2. The kevent is deleted via kevent(..., EV_DELETE)
         *    3. The event is dequeued from the signalfd
         */
        kn = knote_lookup(filt, sig[i].ssi_signo);
        if (kn == NULL)
            continue;

        dbg_printf("got signal %d", sig[i].ssi_signo);
        memcpy(dst, &kn->kev, sizeof(*dst));
        /* TODO: dst->data should be the number of times the signal occurred */
        dst->data = 1;  

        if (kn->kev.flags & EV_DISPATCH || kn->kev.flags & EV_ONESHOT) {
            pthread_rwlock_wrlock(&filt->kf_mtx);
            sigdelset(&filt->kf_sigmask, dst->ident);
            update_sigmask(filt); /* TODO: error checking */
            pthread_rwlock_unlock(&filt->kf_mtx);
        }
        if (kn->kev.flags & EV_DISPATCH)
            KNOTE_DISABLE(kn);
        if (kn->kev.flags & EV_ONESHOT) 
            knote_free(filt, kn);

        dst++; 
        nevents++;
    }

    return (nevents);
}

int
evfilt_signal_knote_create(struct filter *filt, struct knote *kn)
{
    if (kn->kev.ident >= SIGNAL_MAX) {
        dbg_printf("bad signal number %u", (u_int) kn->kev.ident);
        return (-1);
    }

    kn->kev.flags |= EV_CLEAR;
    sigaddset(&filt->kf_sigmask, kn->kev.ident);

    return (update_sigmask(filt));

}

int
evfilt_signal_knote_modify(struct filter *filt, struct knote *kn, 
        const struct kevent *kev)
{
    return (-1); /* FIXME - STUB */
}

int
evfilt_signal_knote_delete(struct filter *filt, struct knote *kn)
{   
    sigdelset(&filt->kf_sigmask, kn->kev.ident);

    return (update_sigmask(filt));
}

int
evfilt_signal_knote_enable(struct filter *filt, struct knote *kn)
{
    sigaddset(&filt->kf_sigmask, kn->kev.ident);

    return (update_sigmask(filt));
}

int
evfilt_signal_knote_disable(struct filter *filt, struct knote *kn)
{
    return (evfilt_signal_knote_delete(filt, kn));
}


const struct filter evfilt_signal = {
    EVFILT_SIGNAL,
    evfilt_signal_init,
    evfilt_signal_destroy,
    evfilt_signal_copyout,
    evfilt_signal_knote_create,
    evfilt_signal_knote_modify,
    evfilt_signal_knote_delete,
    evfilt_signal_knote_enable,
    evfilt_signal_knote_disable,         
};
