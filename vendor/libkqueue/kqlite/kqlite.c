/*
 * Copyright (c) 2013 Mark Heily <mark@heily.com>
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

#include "./lite.h"

/* Determine what type of kernel event system to use. */
#if defined(__FreeBSD__) || defined(__APPLE__) || defined(__OpenBSD__) || defined(__NetBSD__)
#define USE_KQUEUE
#elif defined(__linux__)
#define USE_EPOLL
#include <pthread.h>
#include <sys/epoll.h>
#include <sys/signalfd.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#else
#error Unsupported operating system type
#endif

#if defined(USE_KQUEUE)
typedef int kqueue_t;
#elif defined(USE_EPOLL)
struct kqueue {
    int epfd;            /* epoll */
    int inofd;           /* inotify */
    int timefd;          /* timerfd */
    int sigfd;           /* signalfd */
    sigset_t sigmask;
    pthread_mutex_t kq_mtx;
};
#endif

/* Initialize the event descriptor */
int
kq_init(kqueue_t kq)
{
#if defined(USE_KQUEUE)
    kq = kqueue();

    return (kq);
#elif defined(USE_EPOLL)
    if (pthread_mutex_init(&kq->kq_mtx, NULL) != 0)
        return (-1);
    kq->epfd = epoll_create(10);
    sigemptyset(&kq->sigmask);

    return (kq->epfd);
#endif
}

/* Add a new item to the list of events to be monitored */
int
kq_add(kqueue_t kq, const kevent_t *ev)
{
    int rv = 0;
#if defined(USE_KQUEUE)
    //TODO
#elif defined(USE_EPOLL)
    struct epoll_event epev;
    kevent_t *evcopy;
    int sigfd;

    /* Save a copy of the kevent so kq_wait() can use it later */
    evcopy = malloc(sizeof(*evcopy));
    if (evcopy == NULL)
        return (-1);
    memcpy (evcopy, ev, sizeof(*evcopy));

    switch (ev->ident) {
        case SOURCE_READ:
            epev.events = EPOLLIN;
            epev.data.ptr = evcopy;
            rv = epoll_ctl(kq->epfd, EPOLL_CTL_ADD, ev->ident, &epev);

        case SOURCE_WRITE:
            epev.events = EPOLLOUT;
            epev.data.ptr = evcopy;
            rv = epoll_ctl(kq->epfd, EPOLL_CTL_ADD, ev->ident, &epev);

        case SOURCE_VNODE:
            //TODO: create an inotifyfd, create an epollfd, add the inotifyfd to the epollfd, set epollfd.data.ptr = evcopy, add epollfd to kq->epfd.
            rv = -1;
            break;

        case SOURCE_SIGNAL:
            pthread_mutex_lock(&kq->kq_mtx);
            sigaddset(&kq->sigmask, ev->ident);
            sigfd = signalfd(kq->sigfd, &kq->sigmask, 0);
            pthread_mutex_unlock(&kq->kq_mtx);
            if (sigfd < 0) {
                rv = -1;
            } else {
                rv = 0;
            }
            break;

        case SOURCE_TIMER:
            //TODO
            rv = -1;
            break;

        default:
            rv = -1;
            return (-1);
    }

//    if (rv < 0)
//        free(evcopy);
#endif
    return (rv);
}

/* Delete an item from the list of events to be monitored */
int
kq_remove(kqueue_t kq, const kevent_t *ev)
{
    int rv = 0;
    int sigfd;
#if defined(USE_KQUEUE)
    //TODO
#elif defined(USE_EPOLL)
    struct epoll_event epev;

    switch (ev->ident) {
        case SOURCE_READ:
        case SOURCE_WRITE:
            rv = epoll_ctl(kq->epfd, EPOLL_CTL_DEL, ev->ident, &epev);
            break;

        case SOURCE_VNODE:
            //TODO
            break;

        case SOURCE_SIGNAL:
            pthread_mutex_lock(&kq->kq_mtx);
            sigdelset(&kq->sigmask, ev->ident);
            sigfd = signalfd(kq->sigfd, &kq->sigmask, 0);
            pthread_mutex_unlock(&kq->kq_mtx);
            if (sigfd < 0) {
                rv = -1;
            } else {
                rv = 0;
            }
            break;

        case SOURCE_TIMER:
            //TODO
            break;

        default:
            rv = 0;
            break;
    }
#endif
    return (rv);
}

/* Wait for an event */
int
kq_wait(kqueue_t kq, kevent_t *ev, const struct timespec *timeout)
{
    int rv = 0;
#if defined(USE_KQUEUE)
    //TODO
#elif defined(USE_EPOLL)
    struct epoll_event epev;
    int eptimeout;

    /* Convert timeout to the format used by epoll_wait() */
    if (timeout == NULL) 
        eptimeout = -1;
    else
        eptimeout = (1000 * timeout->tv_sec) + (timeout->tv_nsec / 1000000);

    rv = epoll_wait(kq->epfd, &epev, 1, eptimeout);
    //FIXME: handle timeout
    if (rv > 0) {
        if (epev.data.fd == kq->sigfd) {
            // FIXME: data.fd isn't actually set :(
            // Special case: a signal was received
            // ...
        } else {
            // Normal case: data.ptr is a kevent_t (see evcopy from above)
            // ...
        }
    } 
#endif
    return (rv == 1 ? 0 : -1);
}
