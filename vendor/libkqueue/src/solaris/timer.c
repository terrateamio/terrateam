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

#include "sys/event.h"
#include "private.h"

#ifndef NDEBUG
static char *
itimerspec_dump(struct itimerspec *ts)
{
    static char __thread buf[1024];

    snprintf(buf, sizeof(buf),
            "itimer: [ interval=%lu s %lu ns, next expire=%lu s %lu ns ]",
            ts->it_interval.tv_sec,
            ts->it_interval.tv_nsec,
            ts->it_value.tv_sec,
            ts->it_value.tv_nsec
           );

    return (buf);
}
#endif

/* Convert milliseconds into seconds+nanoseconds */
static void
convert_msec_to_itimerspec(struct itimerspec *dst, int src, int oneshot)
{
    time_t sec, nsec;

    sec = src / 1000;
    nsec = (src % 1000) * 1000000;

    /* Set the interval */
    if (oneshot) {
        dst->it_interval.tv_sec = 0;
        dst->it_interval.tv_nsec = 0;
    } else {
        dst->it_interval.tv_sec = sec;
        dst->it_interval.tv_nsec = nsec;
    }

    /* Set the initial expiration */
    dst->it_value.tv_sec = sec;
    dst->it_value.tv_nsec = nsec;
    dbg_printf("%s", itimerspec_dump(dst));
}

static int
ktimer_create(struct filter *filt, struct knote *kn)
{
    port_notify_t pn;
    struct sigevent se;
    struct itimerspec ts;
    timer_t timerid;

    kn->kev.flags |= EV_CLEAR;

    pn.portnfy_port = filt->kf_kqueue->kq_port;
    pn.portnfy_user = NULL;

    se.sigev_notify = SIGEV_PORT;
    se.sigev_value.sival_ptr = &pn;

    if (timer_create (CLOCK_MONOTONIC, &se, &timerid) < 0) {
        dbg_perror("timer_create(2)"); 
        return (-1);
    }
   
    convert_msec_to_itimerspec(&ts, kn->kev.data, kn->kev.flags & EV_ONESHOT);
    if (timer_settime(timerid, 0, &ts, NULL) < 0) {
        dbg_perror("timer_settime(2)");
        (void) timer_delete(timerid);
        return (-1);
    }

    kn->data.timerid = timerid;
    dbg_printf("created timer with id #%lu", (unsigned long) timerid);

    return (0);
}

int
evfilt_timer_init(struct filter *filt)
{
    return (0);
}

void
evfilt_timer_destroy(struct filter *filt)
{
    return;
}

int
evfilt_timer_copyout(struct filter *filt, 
            struct kevent *dst, 
            int nevents)
{
    port_event_t *pe = &filt->kf_kqueue->kq_evt;
    timer_t timerid;
    struct knote *kn;

    timerid = pe->portev_object;
    kn = knote_lookup(filt, timerid);

    dbg_printf("knote=%p", kn);
    memcpy(dst, &kn->kev, sizeof(*dst));
    //TODO:
    //if (ev->events & EPOLLERR)
    //    dst->fflags = 1; /* FIXME: Return the actual timer error */

    /* FIXME: On return, data contains the number of times the
       timer has been trigered.
     */
    dst->data = 1;  //workaround

    if (kn->kev.flags & EV_DISPATCH) {
        KNOTE_DISABLE(kn);
        timer_delete(kn->data.timerid);
    } else if (kn->kev.flags & EV_ONESHOT) {
        timer_delete(kn->data.timerid);
        knote_free(filt, kn);
    }

    return (1);
}

int
evfilt_timer_knote_create(struct filter *filt, struct knote *kn)
{
    return ktimer_create(filt, kn);
}

int
evfilt_timer_knote_modify(struct filter *filt, struct knote *kn, 
        const struct kevent *kev)
{
    return (0); /* STUB */
}

int
evfilt_timer_knote_delete(struct filter *filt, struct knote *kn)
{
    return timer_delete(kn->data.timerid);
}

int
evfilt_timer_knote_enable(struct filter *filt, struct knote *kn)
{
    return evfilt_timer_knote_create(filt, kn);
}

int
evfilt_timer_knote_disable(struct filter *filt, struct knote *kn)
{
    return evfilt_timer_knote_delete(filt, kn);
}

const struct filter evfilt_timer = {
    EVFILT_TIMER,
    evfilt_timer_init,
    evfilt_timer_destroy,
    evfilt_timer_copyout,
    evfilt_timer_knote_create,
    evfilt_timer_knote_modify,
    evfilt_timer_knote_delete,
    evfilt_timer_knote_enable,
    evfilt_timer_knote_disable,     
};
