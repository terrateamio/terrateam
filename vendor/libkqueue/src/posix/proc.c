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
#include <sys/queue.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>
#include <unistd.h>

#include <limits.h>

#include "sys/event.h"
#include "private.h"

LIST_HEAD(proc_eventhead, proc_event);

struct proc_event {
    uint64_t pe_kqid;
    pid_t    pe_pid;
    int      pe_status;
    LIST_ENTRY(proc_event) entries;
};

struct evfilt_data {
    pthread_t       wthr_id;
    pthread_mutex_t wthr_mtx;
    struct proc_eventhead wthr_waitq;
    struct proc_eventhead wthr_eventq;
};

static void *
wait_thread(void *arg)
{
    struct filter *filt = (struct filter *) arg;
    struct proc_event *evt;
    int status;
    pid_t pid;
    sigset_t sigmask;

    /* Block all signals */
    sigfillset (&sigmask);
    pthread_sigmask(SIG_BLOCK, &sigmask, NULL);

    for (;;) {

        /* Wait for a child process to exit(2) */
        if ((pid = wait(&status)) < 0) {
            if (errno == EINTR)
                continue;
            dbg_printf("wait(2): %s", strerror(errno));
            break;
        } 

        /* Scan the wait queue to see if anyone is interested */
        pthread_mutex_lock(&filt->kf_data->wthr_mtx);
        LIST_FOREACH(evt, &filt->kf_data->wthr_waitq, entries) {
            if (evt->pe_pid == pid)
                break;
        }
        if (evt == NULL) {
            pthread_mutex_unlock(&filt->kf_data->wthr_mtx);
            continue;
        }

        /* Create a proc_event */
        if (WIFEXITED(status)) {
            evt->pe_status = WEXITSTATUS(status);
        } else if (WIFSIGNALED(status)) {
            /* FIXME: probably not true on BSD */
            evt->pe_status = WTERMSIG(status);
        } else {
            dbg_puts("unexpected code path");
            evt->pe_status = 254; 
        }

        /* Add the event to the eventlist */
        LIST_REMOVE(evt, entries);
        LIST_INSERT_HEAD(&filt->kf_data->wthr_eventq, evt, entries);
        pthread_mutex_unlock(&filt->kf_data->wthr_mtx);

        /* Indicate read(2) readiness */
        /* TODO: error handling */
        filter_raise(filt);
    }

    /* TODO: error handling */

    return (NULL);
}

static int
watch_add(struct filter *filt, struct knote *kn)
{
    pthread_mutex_lock(&filt->kf_data->wthr_mtx);
    abort(); /*XXX-TODO*/
    pthread_mutex_unlock(&filt->kf_data->wthr_mtx);
}

int
evfilt_proc_init(struct filter *filt)
{
    struct evfilt_data *ed;

    if ((ed = calloc(1, sizeof(*ed))) == NULL)
        return (-1);
    pthread_mutex_init(&ed->wthr_mtx, NULL);
    LIST_INIT(&ed->wthr_eventq);
    LIST_INIT(&ed->wthr_waitq);

    if (filter_socketpair(filt) < 0) 
        goto errout;
    if (pthread_create(&ed->wthr_id, NULL, wait_thread, filt) != 0) 
        goto errout;

    return (0);

errout:
    free(ed);
    return (-1);
}

void
evfilt_proc_destroy(struct filter *filt)
{
//TODO:    pthread_cancel(filt->kf_data->wthr_id);
    close(filt->kf_pfd);
}

int
evfilt_proc_copyin(struct filter *filt, 
        struct knote *dst, const struct kevent *src)
{
    if (src->flags & EV_ADD && KNOTE_EMPTY(dst)) {
        memcpy(&dst->kev, src, sizeof(*src));
        watch_add(filt, dst);
    }

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

    pthread_mutex_lock(&filt->kf_data->wthr_mtx);
    LIST_FOREACH(elm, &filt->kf_data->wthr_eventq, entries) {
        kn = knote_lookup(filt, elm->pe_pid);
        if (kn == NULL) {
            LIST_REMOVE(elm, entries);
            free(elm);
            continue;
        }

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

    if (!LIST_EMPTY(&filt->kf_data->wthr_eventq)) {
    /* XXX-FIXME: If there are leftover events on the waitq, 
       re-arm the eventfd. list */
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
