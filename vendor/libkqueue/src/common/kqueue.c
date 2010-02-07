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

static RB_HEAD(kqt, kqueue) kqtree       = RB_INITIALIZER(&kqtree);
static pthread_rwlock_t     kqtree_mtx   = PTHREAD_RWLOCK_INITIALIZER;

static int
kqueue_cmp(struct kqueue *a, struct kqueue *b)
{
    return memcmp(&a->kq_sockfd[1], &b->kq_sockfd[1], sizeof(int)); 
}

RB_GENERATE(kqt, kqueue, entries, kqueue_cmp);

static void
kqueue_free(struct kqueue *kq)
{
    RB_REMOVE(kqt, &kqtree, kq);
    filter_unregister_all(kq);
    free(kq);
}

int
kqueue_validate(struct kqueue *kq)
{
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
}

int
kqueue_lookup(struct kqueue **dst, int kq)
{
    struct kqueue query;
    struct kqueue *ent = NULL;
    int x;

    *dst = NULL;

    query.kq_sockfd[1] = kq;
    pthread_rwlock_rdlock(&kqtree_mtx);
    ent = RB_FIND(kqt, &kqtree, &query);
    pthread_rwlock_unlock(&kqtree_mtx);

    if (ent == NULL) {
        errno = ENOENT;
        return (-1);
    }

    x = kqueue_validate(ent);
    if (x == 1) {
        *dst = ent;
        return (0);
    }
    if (x == 0) {
        /* Avoid racing with other threads to free the same kqfd */
        pthread_rwlock_wrlock(&kqtree_mtx);
        ent = RB_FIND(kqt, &kqtree, &query);
        if (ent != NULL)
            kqueue_free(ent);
        pthread_rwlock_unlock(&kqtree_mtx);
        ent = NULL;
        errno = EBADF;
    }

    return (-1);
}

int __attribute__((visibility("default")))
kqueue(void)
{
    struct kqueue *kq;
    struct kqueue *n1, *n2;
    int rv, tmp;

    kq = calloc(1, sizeof(*kq));
    if (kq == NULL)
        return (-1);
    pthread_mutex_init(&kq->kq_mtx, NULL);

    if (socketpair(AF_UNIX, SOCK_STREAM, 0, kq->kq_sockfd) < 0) 
        goto errout_unlocked;

    pthread_rwlock_wrlock(&kqtree_mtx);

    /* Free any kqueue descriptor that is no longer needed */
    /* Sadly O(N), however needed in the case that a descriptor is
       closed and kevent(2) will never again be called on it. */
    for (n1 = RB_MIN(kqt, &kqtree); n1 != NULL; n1 = n2) {
        n2 = RB_NEXT(kqt, &kqtree, n1);
        rv = kqueue_validate(n1);
        if (rv == 0)
            kqueue_free(n1);
        if (rv < 0)
            goto errout;
    }

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
    if (kq->kq_sockfd[0] != kq->kq_sockfd[1]) {
        tmp = errno;
        (void)close(kq->kq_sockfd[0]);
        (void)close(kq->kq_sockfd[1]);
        errno = tmp;
    }
    free(kq);
    return (-1);
}
