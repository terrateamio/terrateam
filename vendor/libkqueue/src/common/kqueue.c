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
#include <poll.h>
#include <pthread.h>
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/queue.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <string.h>
#include <unistd.h>

#include "sys/event.h"
#include "private.h"

static LIST_HEAD(,kqueue) kqlist 	= LIST_HEAD_INITIALIZER(&kqlist);

#define kqlist_lock()            pthread_mutex_lock(&kqlist_mtx)
#define kqlist_unlock()          pthread_mutex_unlock(&kqlist_mtx)
static pthread_mutex_t    kqlist_mtx 	= PTHREAD_MUTEX_INITIALIZER;
static sigset_t saved_sigmask;

static void
mask_signals(void)
{
   sigset_t mask;

   sigemptyset (&mask);
   if (pthread_sigmask(SIG_BLOCK, &mask, &saved_sigmask) != 0)
       sigemptyset (&saved_sigmask);
}

static void
unmask_signals(void)
{
   pthread_sigmask(SIG_SETMASK, &saved_sigmask, NULL);
}

struct kqueue *
kqueue_lookup(int kq)
{
    struct kqueue *ent = NULL;

    kqlist_lock();
    LIST_FOREACH(ent, &kqlist, entries) {
        if (ent->kq_sockfd[1] == kq)
            break;
    }
    kqlist_unlock();

    return (ent);
}

static void
kqueue_shutdown(struct kqueue *kq)
{
    dbg_puts("shutdown invoked\n");

    kqlist_lock();
    LIST_REMOVE(kq, entries);
    kqlist_unlock();
    filter_unregister_all(kq);
    free(kq);
}

void
kqueue_lock(struct kqueue *kq)
{
    dbg_puts("kqueue_lock()");
    pthread_mutex_lock(&kq->kq_mtx);
}

void
kqueue_unlock(struct kqueue *kq)
{
    dbg_puts("kqueue_unlock()");
    pthread_mutex_unlock(&kq->kq_mtx);
}

int
kqueue(void)
{
    struct kqueue *kq;
    int rv;

    kq = calloc(1, sizeof(*kq));
    if (kq == NULL)
        return (-1);
    pthread_mutex_init(&kq->kq_mtx, NULL);

    if (socketpair(AF_LOCAL, SOCK_STREAM, 0, kq->kq_sockfd) < 0) 
        goto errout;

    kqlist_lock();
    mask_signals();
    rv = filter_register_all(kq);
    if (rv == 0) {
        LIST_INSERT_HEAD(&kqlist, kq, entries);
    }
    unmask_signals();
    kqlist_unlock();

    if (rv != 0) 
        goto errout;

    dbg_printf("created kqueue: fd=%d", kq->kq_sockfd[1]);
    return (kq->kq_sockfd[1]);

errout:
    if (kq->kq_sockfd[0] != kq->kq_sockfd[1]) {
        close(kq->kq_sockfd[0]);
        close(kq->kq_sockfd[1]);
    }
    free(kq);
    return (-1);
}

void
kqueue_free(int kqfd)
{
    struct kqueue *kq;

    if ((kq = kqueue_lookup(kqfd)) == NULL)
        return;

    kqueue_shutdown(kq);
}
