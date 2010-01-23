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
    filt->kf_pfd = eventfd_create();
    if (filt->kf_pfd < 0) 
        return (-1);

    return (0);
}

void
evfilt_user_destroy(struct filter *filt)
{
    close(filt->kf_pfd);    /* TODO: do this in the parent */
    return;
}

int
evfilt_user_copyin(struct filter *filt, 
        struct knote *dst, const struct kevent *src)
{
    u_int ffctrl;
    struct kevent *kev;

    if (src->flags & EV_ADD && KNOTE_EMPTY(dst)) 
        memcpy(&dst->kev, src, sizeof(*src));
    kev = &dst->kev;
    if (src->flags & EV_ENABLE) {
        dst->kev.flags &= ~EV_DISABLE;
        /* FIXME: what happens if NOTE_TRIGGER is in fflags?
           should the event fire? */
    }
    if (src->flags & EV_DISABLE)
        dst->kev.flags |= EV_DISABLE;

    /* FIXME: can oneshot be added after the knote is already created? */
    if (src->flags & EV_ONESHOT)
        dst->kev.flags |= EV_ONESHOT;

    /* Excerpted from sys/kern/kern_event.c in FreeBSD HEAD */
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

    if ((!(dst->kev.flags & EV_DISABLE)) && src->fflags & NOTE_TRIGGER) {
        dst->kev.fflags |= NOTE_TRIGGER;
        eventfd_raise(filt->kf_pfd);
    }

    return (0);
}

int
evfilt_user_copyout(struct filter *filt, 
            struct kevent *dst, 
            int maxevents)
{
    struct knote *kn, *kn_next;
    int nevents = 0;
  
    pthread_rwlock_rdlock(&filt->kf_mtx);
    kn = LIST_FIRST(&filt->kf_watchlist);
    pthread_rwlock_unlock(&filt->kf_mtx);

    for (; kn != NULL; kn = kn_next) {
        pthread_rwlock_rdlock(&filt->kf_mtx);
        kn_next = LIST_NEXT(kn, entries);
        pthread_rwlock_unlock(&filt->kf_mtx);

        /* Skip knotes that have not been triggered */
        if (!(kn->kev.fflags & NOTE_TRIGGER))
                continue;

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
        if (kn->kev.flags & EV_ONESHOT) 
            knote_free(filt, kn);
        if (kn->kev.flags & EV_CLEAR)
            kn->kev.fflags &= ~NOTE_TRIGGER;
        if (kn->kev.flags & (EV_DISPATCH | EV_CLEAR | EV_ONESHOT))
            eventfd_lower(filt->kf_pfd);

        dst++;
        if (++nevents == maxevents)
            break;
    }

    /* This should normally never happen but is here for debugging */
    if (nevents == 0) {
        dbg_puts("spurious wakeup");
        eventfd_lower(filt->kf_pfd);
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
        eventfd_raise(filt->kf_pfd);
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
    evfilt_user_copyin,
    evfilt_user_copyout,
    evfilt_user_knote_create,
    evfilt_user_knote_modify,
    evfilt_user_knote_delete,
    evfilt_user_knote_enable,
    evfilt_user_knote_disable,   
};
