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

/* A request to sleep for a certain time */
struct sleepreq {
    int         pfd;            /* fd to poll for ACKs */
    int         wfd;            /* fd to wake up when sleep is over */
    uintptr_t   ident;          /* from kevent */
    intptr_t    interval;       /* sleep time, in milliseconds */
    struct sleepstat *stat;
};

/* Information about a successful sleep operation */
struct sleepinfo {
    uintptr_t   ident;          /* from kevent */
    uintptr_t   counter;        /* number of times the timer expired */
};

static void *
sleeper_thread(void *arg)
{
    struct sleepreq sr;
    struct sleepinfo si;
    struct timespec req, rem;
    sigset_t        mask;
    ssize_t         cnt;
    bool            cts = true;     /* Clear To Send */
    char            buf[1];

    pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS, NULL);

    /* Copyin the request */
    memcpy(&sr, arg, sizeof(sr));
    free(arg);

    /* Initialize the response */
    si.ident = sr.ident;
    si.counter = 0;

    /* Convert milliseconds into seconds+nanoseconds */
    req.tv_sec = sr.interval / 1000;
    req.tv_nsec = (sr.interval % 1000) * 1000000;

    /* Block all signals */
    sigfillset(&mask);
    (void) pthread_sigmask(SIG_BLOCK, &mask, NULL);

    for (;;) {

        /* Sleep */
        if (nanosleep(&req, &rem) < 0) {
            //TODO: handle eintr, spurious wakeups
            dbg_perror("nanosleep(2)");
        }
        si.counter++;
        dbg_printf(" -------- sleep over (CTS=%d)----------", cts);

        /* Test if the previous wakeup has been acknowledged */
        if (!cts) {
            cnt = read(sr.wfd, &buf, 1);
            if (cnt < 0) {
                if (errno == EAGAIN || errno == EWOULDBLOCK) {
                    ;
                } else {
                    dbg_perror("read(2)");
                    break;
                }
            } else if (cnt == 0) {
                dbg_perror("short read(2)");
                break;
            } else {
                cts = true;
            }
        }

        /* Wake up kevent waiters if they are ready */
        if (cts) {
            cnt = write(sr.wfd, &si, sizeof(si));
            if (cnt < 0) {
                /* FIXME: handle EAGAIN and EINTR */
                dbg_perror("write(2)");
            } else if (cnt < sizeof(si)) {
                dbg_puts("FIXME: handle short write"); 
            } 
            cts = false;
            si.counter = 0;
        }
    }

    return (NULL);
}

static int
_timer_create(struct filter *filt, struct knote *kn)
{
    pthread_attr_t attr;
    struct sleepreq *req;
    kn->kev.flags |= EV_CLEAR;

    req = malloc(sizeof(*req));
    if (req == NULL) {
        dbg_perror("malloc");
        return (-1);
    }
    req->pfd = filt->kf_pfd;
    req->wfd = filt->kf_wfd;
    req->ident = kn->kev.ident;
    req->interval = kn->kev.data;

    pthread_attr_init(&attr);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    if (pthread_create(&kn->data.tid, &attr, sleeper_thread, req) != 0) {
        dbg_perror("pthread_create");
        pthread_attr_destroy(&attr);
        free(req);
        return (-1);
    }
    pthread_attr_destroy(&attr);

    return (0);
}

static int
_timer_delete(struct knote *kn)
{
    if (pthread_cancel(kn->data.tid) != 0) {
        /* Race condition: sleeper_thread exits before it is cancelled */
        if (errno == ENOENT)
            return (0);
        dbg_perror("pthread_cancel(3)");
        return (-1);
    }
    return (0);
}

int
evfilt_timer_init(struct filter *filt)
{
    int fd[2];

    if (socketpair(AF_UNIX, SOCK_STREAM, 0, fd) < 0) {
        dbg_perror("socketpair(3)");
        return (-1);
    }
    if (fcntl(fd[0], F_SETFL, O_NONBLOCK) < 0
        || fcntl(fd[1], F_SETFL, O_NONBLOCK) < 0) {
        dbg_perror("fcntl(2)");
        close(fd[0]);
        close(fd[1]);
        return (-1);
    }

    filt->kf_wfd = fd[0];
    filt->kf_pfd = fd[1];

    return (0);
}

void
evfilt_timer_destroy(struct filter *filt)
{
    (void) close(filt->kf_wfd);
    (void) close(filt->kf_pfd);
}

int
evfilt_timer_copyout(struct filter *filt, 
            struct kevent *dst, 
            int nevents)
{
    struct sleepinfo    si;
    ssize_t       cnt;
    struct knote *kn;

    /* Read the ident */
    cnt = read(filt->kf_pfd, &si, sizeof(si));
    if (cnt < 0) {
        /* FIXME: handle EAGAIN and EINTR */
        dbg_printf("read(2): %s", strerror(errno));
        return (-1);
    } else if (cnt < sizeof(si)) {
        dbg_puts("error: short read");
        return (-1);
    }

    /* Acknowlege receipt */
    cnt = write(filt->kf_pfd, ".", 1);
    if (cnt < 0) {
        /* FIXME: handle EAGAIN and EINTR */
        dbg_printf("write(2): %s", strerror(errno));
        return (-1);
    } else if (cnt < 1) {
        dbg_puts("error: short write");
        return (-1);
    }

    kn = knote_lookup(filt, si.ident);

    /* Race condition: timer events remain queued even after
       the knote is deleted. Ignore these events */
    if (kn == NULL)
        return (0);

    dbg_printf("knote=%p", kn);
    memcpy(dst, &kn->kev, sizeof(*dst));

    dst->data = si.counter;

    if (kn->kev.flags & EV_DISPATCH) {
        KNOTE_DISABLE(kn);
        _timer_delete(kn);
    } else if (kn->kev.flags & EV_ONESHOT) {
        _timer_delete(kn);
        knote_free(filt, kn);
    } 

    return (1);
}

int
evfilt_timer_knote_create(struct filter *filt, struct knote *kn)
{
    return _timer_create(filt, kn);
}

int
evfilt_timer_knote_modify(struct filter *filt, struct knote *kn, 
        const struct kevent *kev)
{
    return (-1); /* STUB */
}

int
evfilt_timer_knote_delete(struct filter *filt, struct knote *kn)
{
    if (kn->kev.flags & EV_DISABLE)
        return (0);

    dbg_printf("deleting timer # %d", (int) kn->kev.ident);
    return _timer_delete(kn);
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
