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

#include "sys/event.h"
#include "private.h"

int
evfilt_user_init(struct filter *filt)
{
    return filter_socketpair(filt);
}

void
evfilt_user_destroy(struct filter *filt)
{
    close(filt->kf_wfd);    /* TODO: do this in the parent */
    return;
}

int
evfilt_user_copyin(struct filter *filt, 
        struct knote *dst, const struct kevent *src)
{
    u_int ffctrl;
    struct kevent *kev;

    if (src->flags & EV_ADD && KNOTE_EMPTY(dst)) {
        memcpy(&dst->kev, src, sizeof(*src));
    }
    kev = &dst->kev;

    /* Based on sys/kern/kern_event.c in FreeBSD HEAD */
    ffctrl = kev->fflags & NOTE_FFCTRLMASK;
    kev->fflags &= NOTE_FFLAGSMASK;
    switch (ffctrl) {
        case NOTE_FFNOP:
            break;

        case NOTE_FFAND:
            kev->fflags &= src->fflags;
            break;

        case NOTE_FFOR:
            kev->fflags |= src->fflags;
            break;

        case NOTE_FFCOPY:
            kev->fflags = kev->fflags;
            break;

        default:
            /* XXX Return error? */
            break;
    }

    return (-1);
}

int
evfilt_user_copyout(struct filter *filt, 
            struct kevent *dst, 
            int nevents)
{
    return (0);
}

const struct filter evfilt_user = {
    EVFILT_USER,
    evfilt_user_init,
    evfilt_user_destroy,
    evfilt_user_copyin,
    evfilt_user_copyout,
};
