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

static int kqueue_initialized;          /* Set to 1 by kqueue_init() */

static LIST_HEAD(,kqueue) kqlist 	= LIST_HEAD_INITIALIZER(&kqlist);
static size_t kqcount;

static pthread_rwlock_t    kqlist_mtx 	= PTHREAD_RWLOCK_INITIALIZER;

struct kqueue *
kqueue_lookup(int kq)
{
    struct kqueue *ent = NULL;

    pthread_rwlock_rdlock(&kqlist_mtx);
    LIST_FOREACH(ent, &kqlist, entries) {
        if (ent->kq_sockfd[1] == kq)
            break;
    }
    pthread_rwlock_unlock(&kqlist_mtx);

    return (ent);
}

/* Must hold the kqlist_mtx when calling this */
void
kqueue_free(struct kqueue *kq)
{
    dbg_printf("kqueue_free() on fd %d", kq->kq_sockfd[1]);
    LIST_REMOVE(kq, entries);
    filter_unregister_all(kq);
    free(kq);
}

static int
kqueue_init(void)
{
    if (kqueue_init_hook() < 0)
        return (-1);

    kqueue_initialized = 1;
    return (0);
}

int
kqueue(void)
{
    struct kqueue *kq;

    kq = calloc(1, sizeof(*kq));
    if (kq == NULL)
        return (-1);
    pthread_mutex_init(&kq->kq_mtx, NULL);

    if (socketpair(AF_UNIX, SOCK_STREAM, 0, kq->kq_sockfd) < 0) 
        goto errout_unlocked;

    pthread_rwlock_wrlock(&kqlist_mtx);
    if (!kqueue_initialized && kqueue_init() < 0) 
        goto errout;
    if (filter_register_all(kq) < 0)
        goto errout;
    if (kqlist_insert_hook(kq) < 0)
        goto errout;
    if (kqueue_gc() < 0)
        goto errout;
    LIST_INSERT_HEAD(&kqlist, kq, entries);
    kqcount++;
    pthread_rwlock_unlock(&kqlist_mtx);

    dbg_printf("created kqueue: fd=%d", kq->kq_sockfd[1]);
    return (kq->kq_sockfd[1]);

errout:
    pthread_rwlock_unlock(&kqlist_mtx);

errout_unlocked:
    //FIXME: unregister_all filters
    if (kq->kq_sockfd[0] != kq->kq_sockfd[1]) {
        // FIXME: close() may clobber errno in the case of EINTR
        close(kq->kq_sockfd[0]);
        close(kq->kq_sockfd[1]);
    }
    free(kq);
    return (-1);
}
