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
#include <time.h>
#include <unistd.h>

/* Linux equivalents to kqueue(2) */
#include <sys/timerfd.h>

#include "sys/event.h"
#include "private.h"

static void timer_convert(struct itimerspec *dst, int src);

struct evfilt_data {
    int dummy;
};

/*
 * Determine the smallest interval used by active timers.
 */
static int
update_timeres(struct filter *filt)
{
    struct knote *kn;
    struct itimerspec tval;
    u_int cur = filt->kf_timeres;

    if (KNOTELIST_EMPTY(&filt->knl)) {
        abort();
    }

    /* Find the smallest timeout interval */
    //FIXME not optimized
    KNOTELIST_FOREACH(kn, &filt->knl) {
        dbg_printf("cur=%d new=%d", cur, (int) kn->kev.data);
        if (cur == 0 || kn->kev.data < cur)
            cur = kn->kev.data;
    }

    dbg_printf("cur=%d res=%d", cur, filt->kf_timeres);
    if (cur == filt->kf_timeres) 
        return (0);

    dbg_printf("new timer interval = %d", cur);
    filt->kf_timeres = cur;

    /* Convert from miliseconds to seconds+nanoseconds */
    timer_convert(&tval, cur);
    if (timerfd_settime(filt->kf_pfd, 0, &tval, NULL) < 0) {
        dbg_printf("signalfd(2): %s", strerror(errno));
        return (-1);
    }

    return (0);
}

/* Convert milliseconds into seconds+nanoseconds */
static void
timer_convert(struct itimerspec *dst, int src)
{
    struct timespec now;
    time_t sec, nsec;

    /* Set the interval */
    /* XXX-FIXME: this is probably horribly wrong :) */
    sec = src / 1000;
    nsec = (src % 1000) * 1000000;
    dst->it_interval.tv_sec = sec;
    dst->it_interval.tv_nsec = nsec;

    /* Set the initial expiration */
    clock_gettime(CLOCK_MONOTONIC, &now);
    dst->it_value.tv_sec = now.tv_sec + sec;
    dst->it_value.tv_nsec = now.tv_nsec + nsec;
}

int
evfilt_timer_init(struct filter *filt)
{
    filt->kf_pfd = timerfd_create(CLOCK_MONOTONIC, 0);
    if (filt->kf_pfd < 0) 
        return (-1);

    return (0);
}

void
evfilt_timer_destroy(struct filter *filt)
{
    close (filt->kf_pfd);
}

int
evfilt_timer_copyin(struct filter *filt, 
        struct knote *dst, const struct kevent *src)
{
    if (src->flags & EV_ADD && KNOTE_EMPTY(dst)) {
        memcpy(&dst->kev, src, sizeof(*src));
        dst->kev.flags |= EV_CLEAR;
    }
    if (src->flags & EV_ADD || src->flags & EV_ENABLE) {
        if (update_timeres(filt) < 0)
            return (-1);
    }
    if (src->flags & EV_DISABLE || src->flags & EV_DELETE) {
        // TODO
    }

    return (0);
}

int
evfilt_timer_copyout(struct filter *filt, 
            struct kevent *dst, 
            int nevents)
{
    //struct knote *kn;
    uint64_t buf;
    int i;
    ssize_t n;

    n = read(filt->kf_pfd, &buf, sizeof(buf));
    if (n < 0 || n < sizeof(buf)) {
        dbg_puts("invalid read from timerfd");
        return (-1);
    }
    n = 1;  // KLUDGE

    //KNOTELIST_FOREACH(kn, &filt->knl) {

    for (i = 0, nevents = 0; i < n; i++) {
#if FIXME
        /* Want to have multiple timers, so maybe multiple timerfds... */
        kn = knote_lookup(filt, sig[i].ssi_signo);
        if (kn == NULL)
            continue;

        /* TODO: dst->data should be the number of times the signal occurred */
        dst->ident = sig[i].ssi_signo;
        dst->filter = EVFILT_SIGNAL;
        dst->udata = kn->kev.udata;
        dst->flags = 0; 
        dst->fflags = 0;
        dst->data = 1;  
        dst++; 
        nevents++;
#endif
    }

    return (nevents);
}

const struct filter evfilt_timer = {
    EVFILT_TIMER,
    evfilt_timer_init,
    evfilt_timer_destroy,
    evfilt_timer_copyin,
    evfilt_timer_copyout,
};
