/*
 * Copyright (c) 2011 Mark Heily <mark@heily.com>
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

#include "../common/private.h"

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
ktimer_delete(struct filter *filt, struct knote *kn)
{
    int rv = 0;

    if (kn->data.pfd == -1)
        return (0);

    dbg_printf("removing timerfd %d from %d", kn->data.pfd, filt->kf_pfd);
    if (epoll_ctl(filt->kf_pfd, EPOLL_CTL_DEL, kn->data.pfd, NULL) < 0) {
        dbg_printf("epoll_ctl(2): %s", strerror(errno));
        rv = -1;
    }
    if (close(kn->data.pfd) < 0) {
        dbg_printf("close(2): %s", strerror(errno));
        rv = -1;
    }

    kn->data.pfd = -1;
    return (rv);
}

int
evfilt_timer_init(struct filter *filt)
{
    filt->kf_pfd = epoll_create(1);
    if (filt->kf_pfd < 0)
        return (-1);

    dbg_printf("timer epollfd = %d", filt->kf_pfd);
    return (0);
}

void
evfilt_timer_destroy(struct filter *filt)
{
    close (filt->kf_pfd);//LAME
}

/* TODO: This entire function is copy+pasted from socket.c
   with minor changes for timerfds.
   Perhaps it could be refactored into a generic epoll_copyout()
   that calls custom per-filter actions.
   */
int
evfilt_timer_copyout(struct filter *filt, 
            struct kevent *dst, 
            int nevents)
{
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
        n = read(kn->data.pfd, &expired, sizeof(expired));
        if (n < 0 || n < sizeof(expired)) {
            dbg_puts("invalid read from timerfd");
            expired = 1;  /* Fail gracefully */
        } 
        dst->data = expired;

        if (kn->kev.flags & EV_DISPATCH) {
            KNOTE_DISABLE(kn);
            ktimer_delete(filt, kn);
        } else if (kn->kev.flags & EV_ONESHOT) {
            ktimer_delete(filt, kn);
            knote_free(filt, kn);
        }

        nevents++;
        dst++;
    }

    return (nevents);
}

int
evfilt_timer_knote_create(struct filter *filt, struct knote *kn)
{
    struct epoll_event ev;
    struct itimerspec ts;
    int tfd;

    kn->kev.flags |= EV_CLEAR;

    tfd = timerfd_create(CLOCK_MONOTONIC, 0);
    if (tfd < 0) {
        dbg_printf("timerfd_create(2): %s", strerror(errno));
        return (-1);
    }
    dbg_printf("created timerfd %d", tfd);

    convert_msec_to_itimerspec(&ts, kn->kev.data, kn->kev.flags & EV_ONESHOT);
    if (timerfd_settime(tfd, 0, &ts, NULL) < 0) {
        dbg_printf("timerfd_settime(2): %s", strerror(errno));
        close(tfd);
        return (-1);
    }

    memset(&ev, 0, sizeof(ev));
    ev.events = EPOLLIN;
    ev.data.ptr = kn;
    if (epoll_ctl(filt->kf_pfd, EPOLL_CTL_ADD, tfd, &ev) < 0) {
        dbg_printf("epoll_ctl(2): %d", errno);
        close(tfd);
        return (-1);
    }

    kn->data.pfd = tfd;
    return (0);
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
    return (ktimer_delete(filt,kn));
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
