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
static pthread_mutex_t    kqlist_mtx 	= PTHREAD_MUTEX_INITIALIZER;
#define kqlist_lock()            pthread_mutex_lock(&kqlist_mtx)
#define kqlist_unlock()          pthread_mutex_unlock(&kqlist_mtx)

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
    pthread_exit(NULL);
}

static void *
kqueue_close_wait(void *arg)
{
    struct kqueue *kq = (struct kqueue *) arg;
    struct pollfd fds[1];
    int n;

    /* Block all signals in this thread */
    sigset_t mask;
    sigfillset(&mask);
    if (sigprocmask(SIG_BLOCK, &mask, NULL) == -1) {
        dbg_printf("sigprocmask: %s", strerror(errno));
        abort();
    }

    /* Watch for the close(2) of the kqueue fd */
    fds[0].fd = kq->kq_sockfd[0];
    fds[0].events = POLLIN;

    /* Almost solves a race condition when close(2) is called immediately 
       after kqueue(2). Also helps prevent signal races. 
     */
    kqlist_unlock();

    for (;;) {
        n = poll(&fds[0], 1, -1);
        if (n == 0)
            continue;           /* Should never happen */
        if (n < 0) {
            if (errno == EINTR)
                continue;
            dbg_printf("poll(2): %s", strerror(errno));
            abort(); //FIXME
        }
    }
    dbg_puts("kqueue: fd closed");

    kqueue_shutdown(kq);

    return (NULL);
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

    kq = calloc(1, sizeof(*kq));
    if (kq == NULL)
        return (-1);
    pthread_mutex_init(&kq->kq_mtx, NULL);

    if (filter_register_all(kq) < 0)
        return (-1);
    
    if (socketpair(AF_LOCAL, SOCK_STREAM, 0, kq->kq_sockfd) < 0) {
        free(kq);
        return (-1);
    }

    kqlist_lock();
    if (pthread_create(&kq->kq_close_tid, NULL, kqueue_close_wait, kq) != 0) {
        close(kq->kq_sockfd[0]);
        close(kq->kq_sockfd[1]);
        free(kq);
        return (-1);
    }

    kqlist_lock();
    LIST_INSERT_HEAD(&kqlist, kq, entries);
    kqlist_unlock();

    dbg_printf("created kqueue: fd=%d", kq->kq_sockfd[1]);
    return (kq->kq_sockfd[1]);
}
