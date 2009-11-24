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

#include <port.h>

#include "sys/event.h"
#include "private.h"

int
evfilt_timer_init(struct filter *filt)
{
    return (-1);
}

void
evfilt_timer_destroy(struct filter *filt)
{
    ;
}

int
evfilt_timer_copyin(struct filter *filt, 
        struct knote *dst, const struct kevent *src)
{
    return (-1);
#if TODO
    if (src->flags & EV_ADD && KNOTE_EMPTY(dst)) {
        memcpy(&dst->kev, src, sizeof(*src));
        dst->kev.flags |= EV_CLEAR;
    }
    if (src->flags & EV_ADD) 
        return ktimer_create(filt, dst);
    if (src->flags & EV_DELETE) 
        return ktimer_delete(filt, dst);
    if (src->flags & EV_ENABLE) 
        return ktimer_create(filt, dst);
    if (src->flags & EV_DISABLE) {
        // TODO: err checking
        (void) ktimer_delete(filt, dst);
        KNOTE_DISABLE(dst);
    }

    return (0);
#endif
}

int
evfilt_timer_copyout(struct filter *filt, 
            struct kevent *dst, 
            int nevents)
{
    return (-1);
#if TODO
    struct epoll_event epevt[MAX_KEVENT];
    struct epoll_event *ev;
    struct knote *kn;
    uint64_t expired;
    int i, nret;
    ssize_t n;

    for (;;) {
        nret = epoll_wait(filt->kf_pfd, &epevt[0], nevents, 0);
        if (nret < 0) {
            if (errno == EINTR)
                continue;
            dbg_perror("epoll_wait");
            return (-1);
        } else {
            break;
        }
    }

    for (i = 0, nevents = 0; i < nret; i++) {
        ev = &epevt[i];
        /* TODO: put in generic debug.c: epoll_event_dump(ev); */
        kn = ev->data.ptr;
        memcpy(dst, &kn->kev, sizeof(*dst));
        if (ev->events & EPOLLERR)
            dst->fflags = 1; /* FIXME: Return the actual timer error */
          
        /* On return, data contains the number of times the
           timer has been trigered.
             */
        n = read(kn->kn_pfd, &expired, sizeof(expired));
        if (n < 0 || n < sizeof(expired)) {
            dbg_puts("invalid read from timerfd");
            expired = 1;  /* Fail gracefully */
        } 
        dst->data = expired;

        if (kn->kev.flags & EV_DISPATCH) 
            KNOTE_DISABLE(kn);
        if (kn->kev.flags & EV_ONESHOT) {
            ktimer_delete(filt, kn);
            knote_free(kn);
        }

        nevents++;
        dst++;
    }

    return (nevents);
#endif
}

const struct filter evfilt_timer = {
    0, //EVFILT_TIMER,
    evfilt_timer_init,
    evfilt_timer_destroy,
    evfilt_timer_copyin,
    evfilt_timer_copyout,
};
