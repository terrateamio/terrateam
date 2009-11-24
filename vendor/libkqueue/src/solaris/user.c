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

#include "sys/event.h"
#include "private.h"

int
evfilt_user_init(struct filter *filt)
{
    return (-1);
}

void
evfilt_user_destroy(struct filter *filt)
{
    return;
}

int
evfilt_user_copyin(struct filter *filt, 
        struct knote *dst, const struct kevent *src)
{
    return (-1);
#if TODO
    u_int ffctrl;
    struct kevent *kev;
    uint64_t counter;

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
        counter = 1;
        if (write(filt->kf_pfd, &counter, sizeof(counter)) < 0) {
            if (errno != EAGAIN) {
                dbg_printf("write(2): %s", strerror(errno));
                return (-1);
            }
        }
        dst->kev.fflags |= NOTE_TRIGGER;
        dbg_puts("knote triggered");
    }
#endif
    return (0);
}

int
evfilt_user_copyout(struct filter *filt, 
            struct kevent *dst, 
            int maxevents)
{
    return (-1);
#if TODO
    struct knote *kn, *kn_next;
    int nevents = 0;
    uint64_t cur;

    /* Reset the counter */
    if (read(filt->kf_pfd, &cur, sizeof(cur)) < sizeof(cur)) {
        dbg_printf("read(2): %s", strerror(errno));
        return (-1);
    }
    dbg_printf("  counter=%llu", (unsigned long long) cur);

    for (kn = LIST_FIRST(&filt->kf_watchlist); kn != NULL; kn = kn_next) {
        kn_next = LIST_NEXT(kn, entries);

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
        if (kn->kev.flags & EV_ONESHOT) {

            /* NOTE: True on FreeBSD but not consistent behavior with
                      other filters. */
            dst->flags &= ~EV_ONESHOT;  

            knote_free(kn);
        }

        dst++;
        if (++nevents == maxevents)
            break;
    }

    return (nevents);
#endif
}

const struct filter evfilt_user = {
    0, //EVFILT_USER,
    evfilt_user_init,
    evfilt_user_destroy,
    evfilt_user_copyin,
    evfilt_user_copyout,
};
