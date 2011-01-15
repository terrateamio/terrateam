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
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <string.h>

#include "private.h"

int KQUEUE_DEBUG = 0;

static RB_HEAD(kqt, kqueue) kqtree       = RB_INITIALIZER(&kqtree);
static pthread_rwlock_t     kqtree_mtx;

CONSTRUCTOR
_libkqueue_init(void)
{
    pthread_rwlock_init(&kqtree_mtx, NULL);
    return (0);
}

static int
kqueue_cmp(struct kqueue *a, struct kqueue *b)
{
    return memcmp(&a->kq_sockfd[1], &b->kq_sockfd[1], sizeof(int)); 
}

RB_GENERATE(kqt, kqueue, entries, kqueue_cmp)

/* Must hold the kqtree_mtx when calling this */
static void
kqueue_free(struct kqueue *kq)
{
    RB_REMOVE(kqt, &kqtree, kq);
    filter_unregister_all(kq);

#ifdef kqueue_free_hook
    kqueue_free_hook(kq);
#endif

    free(kq);
}

static int
kqueue_gc(void)
{
    int rv;
    struct kqueue *n1, *n2;

    /* Free any kqueue descriptor that is no longer needed */
    /* Sadly O(N), however needed in the case that a descriptor is
       closed and kevent(2) will never again be called on it. */
    for (n1 = RB_MIN(kqt, &kqtree); n1 != NULL; n1 = n2) {
        n2 = RB_NEXT(kqt, &kqtree, n1);

        if (n1->kq_ref == 0) {
            kqueue_free(n1);
        } else {
            rv = kqueue_validate(n1);
            if (rv == 0) 
                kqueue_free(n1);
            else if (rv < 0) 
                return (-1);
        }
    }

    return (0);
}

int
kqueue_validate(struct kqueue *kq)
{
#if defined(_WIN32)
    return (0); /* FIXME */
#else
    int rv;
    char buf[1];
    struct pollfd pfd;

    pfd.fd = kq->kq_sockfd[0];
    pfd.events = POLLIN | POLLHUP;
    pfd.revents = 0;

    rv = poll(&pfd, 1, 0);
    if (rv == 0)
        return (1);
    if (rv < 0) {
        dbg_perror("poll(2)");
        return (-1);
    }
    if (rv > 0) {
        /* NOTE: If the caller accidentally writes to the kqfd, it will
                 be considered invalid. */
        rv = recv(kq->kq_sockfd[0], buf, sizeof(buf), MSG_PEEK | MSG_DONTWAIT);
        if (rv == 0) 
            return (0);
        else
            return (-1);
    }

    return (0);
#endif /* WIN32 */
}

void
kqueue_put(struct kqueue *kq)
{
    atomic_dec(&kq->kq_ref);
}

struct kqueue *
kqueue_get(int kq)
{
    struct kqueue query;
    struct kqueue *ent = NULL;

    query.kq_sockfd[1] = kq;
    pthread_rwlock_rdlock(&kqtree_mtx);
    ent = RB_FIND(kqt, &kqtree, &query);
    pthread_rwlock_unlock(&kqtree_mtx);

    /* Check for invalid kqueue objects still in the tree */
    if (ent != NULL && (ent->kq_sockfd[0] < 0 || ent->kq_ref == 0))
        ent = NULL;
    else
        atomic_inc(&ent->kq_ref);

    return (ent);
}

VISIBLE_DECL(int, kqueue(void))
{
	struct kqueue *kq;

    kq = calloc(1, sizeof(*kq));
    if (kq == NULL)
        return (-1);
    kq->kq_ref = 1;
    pthread_mutex_init(&kq->kq_mtx, NULL);

#ifdef NDEBUG
    KQUEUE_DEBUG = 0;
#elif _WIN32
	/* Experimental port, always debug */
	KQUEUE_DEBUG = 1;
#else
    KQUEUE_DEBUG = (getenv("KQUEUE_DEBUG") == NULL) ? 0 : 1;
#endif

    if (kqueue_init_hook(kq) < 0)
        goto errout_unlocked;

    pthread_rwlock_wrlock(&kqtree_mtx);
    if (kqueue_gc() < 0)
        goto errout;
    /* TODO: move outside of the lock if it is safe */
    if (filter_register_all(kq) < 0)
        goto errout;
    RB_INSERT(kqt, &kqtree, kq);
    pthread_rwlock_unlock(&kqtree_mtx);

    dbg_printf("created kqueue, fd=%d", kq->kq_sockfd[1]);
    return (kq->kq_sockfd[1]);

errout:
    pthread_rwlock_unlock(&kqtree_mtx);

errout_unlocked:
    kqueue_free_hook(kq);
    free(kq);
    return (-1);
}
