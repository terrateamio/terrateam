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
#include "../../private.h"

/* Highest signal number supported. POSIX standard signals are < 32 */
#define SIGNAL_MAX      32

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
evfilt_signal_copyin(struct filter *filt, 
        struct knote *dst, const struct kevent *src)
{
    int rv;

    if (src->ident >= SIGNAL_MAX) {
        dbg_printf("unsupported signal number %u", (u_int) src->ident);
        return (-1);
    }

    if (src->flags & EV_ADD && KNOTE_EMPTY(dst)) {
        memcpy(&dst->kev, src, sizeof(*src));
        dst->kev.flags |= EV_CLEAR;
    }
    if (src->flags & EV_ADD || src->flags & EV_ENABLE) 
        sigaddset(&filt->kf_sigmask, src->ident);
    if (src->flags & EV_DISABLE || src->flags & EV_DELETE) 
        sigdelset(&filt->kf_sigmask, src->ident);

    rv = signalfd(filt->kf_pfd, &filt->kf_sigmask, 0);
    dbg_printf("signalfd = %d", filt->kf_pfd);
    if (rv < 0 || rv != filt->kf_pfd) {
        dbg_printf("signalfd(2): %s", strerror(errno));
        return (-1);
    }

    return (0);
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

    /* NOTE: This will consume the signals so they will not be delivered
     * to the process. This differs from kqueue(2) behavior. */
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
        /* TODO: dst->data should be the number of times the signal occurred */
        dst->ident = sig[i].ssi_signo;
        dst->filter = EVFILT_SIGNAL;
        dst->udata = kn->kev.udata;
        dst->flags = 0; 
        dst->fflags = 0;
        dst->data = 1;  
        dst++; 
        nevents++;
    }

    return (nevents);
}

const struct filter evfilt_signal = {
    EVFILT_SIGNAL,
    evfilt_signal_init,
    evfilt_signal_destroy,
    evfilt_signal_copyin,
    evfilt_signal_copyout,
};
