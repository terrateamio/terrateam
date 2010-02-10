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
#include <sys/eventfd.h>
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
    filt->kf_efd = eventfd_create();
    if (filt->kf_efd == NULL)
        return (-1);

    filt->kf_pfd = eventfd_reader(filt->kf_efd);
    if (filt->kf_pfd < 0) 
        return (-1);

    return (0);
}

void
evfilt_user_destroy(struct filter *filt)
{
    eventfd_free(filt->kf_efd);
    return;
}

int
evfilt_user_copyout(struct filter *filt, 
            struct kevent *dst, 
            int maxevents)
{
    struct knote *kn;
    int nevents = 0;
  
    for (kn = knote_dequeue(filt); kn != NULL; kn = knote_dequeue(filt)) {
        memcpy(dst, &kn->kev, sizeof(*dst));
        dst->fflags &= ~NOTE_FFCTRLMASK;     //FIXME: Not sure if needed
        dst->fflags &= ~NOTE_TRIGGER;
        if (kn->kev.flags & EV_DISPATCH) 
            KNOTE_DISABLE(kn);
        if (kn->kev.flags & EV_ADD) {
            /* NOTE: True on FreeBSD but not consistent behavior with
                      other filters. */
            dst->flags &= ~EV_ADD;
        }
        if (kn->kev.flags & EV_CLEAR)
            kn->kev.fflags &= ~NOTE_TRIGGER;
        if (kn->kev.flags & (EV_DISPATCH | EV_CLEAR | EV_ONESHOT))
            eventfd_lower(filt->kf_efd);
        if (kn->kev.flags & EV_ONESHOT) 
            knote_free(filt, kn);

        dst++;
        if (++nevents == maxevents)
            break;
    }

    /* This should normally never happen but is here for debugging */
    if (nevents == 0) {
        dbg_puts("spurious wakeup");
        eventfd_lower(filt->kf_efd);
    }

    return (nevents);
}

int
evfilt_user_knote_create(struct filter *filt, struct knote *kn)
{
#if TODO
    u_int ffctrl;

    //determine if EV_ADD + NOTE_TRIGGER in the same kevent will cause a trigger */
    if ((!(dst->kev.flags & EV_DISABLE)) && src->fflags & NOTE_TRIGGER) {
        dst->kev.fflags |= NOTE_TRIGGER;
        eventfd_raise(filt->kf_pfd);
    }

#endif
    return (0);
}

int
evfilt_user_knote_modify(struct filter *filt, struct knote *kn, 
        const struct kevent *kev)
{
    u_int ffctrl;
    u_int fflags;

    /* Excerpted from sys/kern/kern_event.c in FreeBSD HEAD */
    ffctrl = kev->fflags & NOTE_FFCTRLMASK;
    fflags = kev->fflags & NOTE_FFLAGSMASK;
    switch (ffctrl) {
        case NOTE_FFNOP:
            break;

        case NOTE_FFAND:
            kn->kev.fflags &= fflags;
            break;

        case NOTE_FFOR:
            kn->kev.fflags |= fflags;
            break;

        case NOTE_FFCOPY:
            kn->kev.fflags = fflags;
            break;

        default:
            /* XXX Return error? */
            break;
    }

    if ((!(kn->kev.flags & EV_DISABLE)) && kev->fflags & NOTE_TRIGGER) {
        kn->kev.fflags |= NOTE_TRIGGER;
        knote_enqueue(filt, kn);
        eventfd_raise(filt->kf_efd);
    }

    return (0);
}

int
evfilt_user_knote_delete(struct filter *filt, struct knote *kn)
{
    return (0);
}

int
evfilt_user_knote_enable(struct filter *filt, struct knote *kn)
{
    /* FIXME: what happens if NOTE_TRIGGER is in fflags?
       should the event fire? */
    return (0);
}

int
evfilt_user_knote_disable(struct filter *filt, struct knote *kn)
{
    return (0);
}

const struct filter evfilt_user = {
    EVFILT_USER,
    evfilt_user_init,
    evfilt_user_destroy,
    evfilt_user_copyout,
    evfilt_user_knote_create,
    evfilt_user_knote_modify,
    evfilt_user_knote_delete,
    evfilt_user_knote_enable,
    evfilt_user_knote_disable,   
};
