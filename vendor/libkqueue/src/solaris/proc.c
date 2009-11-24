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
evfilt_proc_init(struct filter *filt)
{
    return (-1);
}

void
evfilt_proc_destroy(struct filter *filt)
{
    ;
}

int
evfilt_proc_copyin(struct filter *filt, 
        struct knote *dst, const struct kevent *src)
{
    return (-1);
#if TODO
    if (src->flags & EV_ADD && KNOTE_EMPTY(dst)) {
        memcpy(&dst->kev, src, sizeof(*src));
        /* TODO: Consider holding the mutex here.. */
        pthread_cond_signal(&filt->kf_data->wait_cond);
    }

    if (src->flags & EV_ADD || src->flags & EV_ENABLE) {
        /* Nothing to do.. */
    }

    return (0);
#endif
}

int
evfilt_proc_copyout(struct filter *filt, 
            struct kevent *dst, 
            int maxevents)
{
    return (-1);
#if TODO
    struct knote *kn, *kn_nxt;
    int nevents = 0;
    uint64_t cur;

    /* Reset the counter */
    if (read(filt->kf_pfd, &cur, sizeof(cur)) < sizeof(cur)) {
        dbg_printf("read(2): %s", strerror(errno));
        return (-1);
    }
    dbg_printf("  counter=%llu", (unsigned long long) cur);

    pthread_mutex_lock(&filt->kf_mtx);
    for (kn = LIST_FIRST(&filt->kf_eventlist); kn != NULL; kn = kn_nxt) {
        kn_nxt = LIST_NEXT(kn, entries);

        kevent_dump(&kn->kev);
        memcpy(dst, &kn->kev, sizeof(*dst));

        if (kn->kev.flags & EV_DISPATCH) {
            KNOTE_DISABLE(kn);
        }
        if (kn->kev.flags & EV_ONESHOT) {
            knote_free(kn);
        } else {
            kn->kev.data = 0;
            LIST_REMOVE(kn, entries);
            LIST_INSERT_HEAD(&filt->kf_watchlist, kn, entries);
        }


        if (++nevents > maxevents)
            break;
        dst++;
    }
    pthread_mutex_unlock(&filt->kf_mtx);

    if (!LIST_EMPTY(&filt->kf_eventlist)) {
    /* XXX-FIXME: If there are leftover events on the waitq, 
       re-arm the eventfd. list */
        abort();
    }

    return (nevents);
#endif
}

const struct filter evfilt_proc = {
    0, //EVFILT_PROC,
    evfilt_proc_init,
    evfilt_proc_destroy,
    evfilt_proc_copyin,
    evfilt_proc_copyout,
};
