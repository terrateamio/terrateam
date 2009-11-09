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
#include <err.h>
#include <fcntl.h>
#include <pthread.h>
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/eventfd.h>
#include <sys/queue.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>
#include <unistd.h>

#include <limits.h>
#include <sys/inotify.h>
#include <sys/epoll.h>

#include "sys/event.h"
#include "private.h"

struct proc_event {
    pid_t pe_pid;
    int   pe_status;
    LIST_ENTRY(proc_event) entries;
};

struct evfilt_data {
    pthread_t       wthr_id;
    pthread_mutex_t wthr_mtx;
    LIST_HEAD(proc_eventhead,proc_event) wthr_event;
};

static void *
wait_thread(void *arg)
{
    struct filter *filt = (struct filter *) arg;
    uint64_t counter = 1;
    const int options = WEXITED | WNOWAIT; 
    struct proc_event *evt;
    siginfo_t si;
    sigset_t sigmask;

    /* Block all signals */
    sigfillset (&sigmask);
    pthread_sigmask(SIG_BLOCK, &sigmask, NULL);

    for (;;) {

        /* Wait for a child process to exit(2) */
        if (waitid(P_ALL, 0, &si, options) != 0)
            break;

        /* Create a proc_event */
        if ((evt = malloc(sizeof(*evt))) == NULL)
            continue;               /* TODO: set filter error flag */
        if (si.si_code == CLD_EXITED) {
            evt->pe_status = si.si_status;
        } else if (si.si_code == CLD_KILLED) {
            /* FIXME: probably not true on BSD */
            /* FIXME: arbitrary non-zero number */
            evt->pe_status = 254; 
        } else {
            /* Should never happen. */
            continue;
        }

        /* Add the event to the eventlist */
        pthread_mutex_lock(&filt->kf_data->wthr_mtx);
        LIST_INSERT_HEAD(&filt->kf_data->wthr_event, evt, entries);
        pthread_mutex_unlock(&filt->kf_data->wthr_mtx);

        /* Indicate read(2) readiness */
        if (write(filt->kf_pfd, &counter, sizeof(counter)) < 0) {
            if (errno != EAGAIN) {
                dbg_printf("write(2): %s", strerror(errno));
                /* TODO: set filter error flag */
                break;
                }
        }
    }

    /* TODO: error handling */

    return (NULL);
}

int
evfilt_proc_init(struct filter *filt)
{
    struct evfilt_data *ed;
    int efd = -1;

    if ((ed = calloc(1, sizeof(*ed))) == NULL)
        return (-1);
    pthread_mutex_init(&ed->wthr_mtx, NULL);
    LIST_INIT(&ed->wthr_event);

    if ((efd = eventfd(0, 0)) < 0) 
        goto errout;
    if (fcntl(filt->kf_pfd, F_SETFL, O_NONBLOCK) < 0) 
        goto errout;
    if (pthread_create(&ed->wthr_id, NULL, wait_thread, filt) != 0) 
        goto errout;

    filt->kf_pfd = efd;

    return (0);

errout:
    if (efd >= 0)
        close(efd);
    free(ed);
    close(filt->kf_pfd);
    return (-1);
}

void
evfilt_proc_destroy(struct filter *filt)
{
    pthread_cancel(filt->kf_data->wthr_id);
    close(filt->kf_pfd);
}

int
evfilt_proc_copyin(struct filter *filt, 
        struct knote *dst, const struct kevent *src)
{
    if (src->flags & EV_ADD && KNOTE_EMPTY(dst)) 
        memcpy(&dst->kev, src, sizeof(*src));

    if (src->flags & EV_ADD || src->flags & EV_ENABLE) {
        /* Nothing to do.. */
    }

    return (0);
}

int
evfilt_proc_copyout(struct filter *filt, 
            struct kevent *dst, 
            int maxevents)
{
    struct proc_eventhead evt;
    struct proc_event *elm;
    struct knote *kn;
    int nevents = 0;
    uint64_t cur;

    /* Reset the counter */
    if (read(filt->kf_pfd, &cur, sizeof(cur)) < sizeof(cur)) {
        dbg_printf("read(2): %s", strerror(errno));
        return (-1);
    }
    dbg_printf("  counter=%llu", (unsigned long long) cur);

    /* Consume the eventlist */
    pthread_mutex_lock(&filt->kf_data->wthr_mtx);
    evt = filt->kf_data->wthr_event;
    LIST_INIT(&filt->kf_data->wthr_event);
    pthread_mutex_unlock(&filt->kf_data->wthr_mtx);

    /* Scan for events that have been triggered */
    KNOTELIST_FOREACH(kn, &filt->knl) {
        LIST_FOREACH(elm, &evt, entries) {
            if (elm->pe_pid == kn->kev.ident) {

                kevent_dump(&kn->kev);
                dst->ident = kn->kev.ident;
                dst->filter = kn->kev.filter;
                dst->udata = kn->kev.udata;
                dst->flags = kn->kev.flags; 
                dst->fflags = NOTE_EXIT;
                dst->data = elm->pe_status;

                if (kn->kev.flags & EV_DISPATCH) {
                    KNOTE_DISABLE(kn);
                }
                if (kn->kev.flags & EV_ONESHOT) 
                    knote_free(kn);

                LIST_REMOVE(elm, entries);
                free(elm);

                if (++nevents > maxevents)
                    break;
                dst++;
            }
        }
    }

    if (!LIST_EMPTY(&evt)) {
    /* XXX-FIXME: If there are leftover events, put them back
       onto the wthr_event list */
        abort();
    }

    return (nevents);
}

const struct filter evfilt_proc = {
    EVFILT_PROC,
    evfilt_proc_init,
    evfilt_proc_destroy,
    evfilt_proc_copyin,
    evfilt_proc_copyout,
};
