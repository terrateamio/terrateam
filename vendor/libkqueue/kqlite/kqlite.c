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
#include "./utarray.h"

/* The maximum number of events that can be returned in 
   a single kq_event() call 
 */
#define EPEV_BUF_MAX 512

#include <unistd.h>

/* Determine what type of kernel event system to use. */
#if defined(__FreeBSD__) || defined(__APPLE__) || defined(__OpenBSD__) || defined(__NetBSD__)
#define USE_KQUEUE
#include <sys/event.h>
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


/* Linux supports a subset of these filters. */
#if defined(USE_EPOLL)
#define EVFILT_READ     (0)
#define EVFILT_WRITE    (1)
#define EVFILT_VNODE    (2)
#define EVFILT_SIGNAL   (3)
#define EVFILT_TIMER    (4)
#define EVFILT_SYSCOUNT (5)
#endif

struct kqueue {
#if defined(USE_KQUEUE)
    int kqfd;            /* kqueue(2) descriptor */
#elif defined(USE_EPOLL)
    int epfd;            /* epoll */
    int wfd[EVFILT_SYSCOUNT]; /* an event wait descriptor for each EVFILT_* */
    sigset_t sigmask;
    UT_array *kev;  /* All of the active kevents */
    pthread_mutex_t kq_mtx;
#else
#error Undefined event system
#endif
};

static inline void
kq_lock(kqueue_t kq)
{
    if (pthread_mutex_lock(&kq->kq_mtx) != 0) 
        abort();
}

static inline void
kq_unlock(kqueue_t kq)
{
    if (pthread_mutex_unlock(&kq->kq_mtx) != 0) 
        abort();
}

UT_icd kevent_icd = { sizeof(struct kevent), NULL, NULL, NULL };

/* Initialize the event descriptor */
kqueue_t
kq_init(void)
{
    struct kqueue *kq;

    if ((kq = malloc(sizeof(*kq))) == NULL)
        return (NULL);

#if defined(USE_KQUEUE)
    kq->kqfd = kqueue();
    if (kq->kqfd < 0) {
        free(kq);
        return (NULL);
    }
    
#elif defined(USE_EPOLL)
    if (pthread_mutex_init(&kq->kq_mtx, NULL) != 0)
        goto errout;
    kq->epfd = epoll_create(10);
    if (kq->epfd < 0)
        goto errout;
    sigemptyset(&kq->sigmask);
    kq->wfd[EVFILT_SIGNAL] = signalfd(-1, &kq->sigmask, 0);

    utarray_new(kq->kev, &kevent_icd);

    // FIXME: check that all members of kq->wfd are valid

    return (kq);

errout:
    free(kq);
    if (kq->epfd >= 0) close(kq->epfd);
    //FIXME: something like: if (kq->wfd[EVFILT_SIGNAL] >= 0) free(kq->epfd);
    return (NULL);
#endif
}

void
kq_free(kqueue_t kq)
{
#if defined(USE_KQUEUE)
    close(kq.kqfd);
    
#elif defined(USE_EPOLL)
    close(kq->epfd);
    utarray_free(kq->kev);
    //FIXME: there are a more things to do
#endif
    free(kq);
}

#if defined(USE_EPOLL)

/* Add a new item to the list of events to be monitored */
static inline int
kq_add(kqueue_t kq, const struct kevent *ev)
{
    int rv = 0;
    struct epoll_event epev;
    struct kevent *evcopy;
    int sigfd;

    /* Save a copy of the kevent so kq_event() can use it after
       the event occurs.
     */
    evcopy = malloc(sizeof(*evcopy));
    if (evcopy == NULL)
        return (-1);
    memcpy (evcopy, ev, sizeof(*evcopy));
    kq_lock(kq);
    utarray_push_back(kq->kev, evcopy);
    epev.data.u32 = utarray_len(kq->kev);
    kq_unlock(kq);

    switch (ev->ident) {
        case EVFILT_READ:
            epev.events = EPOLLIN;
            rv = epoll_ctl(kq->epfd, EPOLL_CTL_ADD, ev->ident, &epev);

        case EVFILT_WRITE:
            epev.events = EPOLLOUT;
            rv = epoll_ctl(kq->epfd, EPOLL_CTL_ADD, ev->ident, &epev);

        case EVFILT_VNODE:
            //TODO: create an inotifyfd, create an epollfd, add the inotifyfd to the epollfd, set epollfd.data.ptr = evcopy, add epollfd to kq->epfd.
            rv = -1;
            break;

        case EVFILT_SIGNAL:
            kq_lock(kq);
            sigaddset(&kq->sigmask, ev->ident);
            sigfd = signalfd(kq->wfd[EVFILT_SIGNAL], &kq->sigmask, 0);
            kq_unlock(kq);
            if (sigfd < 0) {
                rv = -1;
            } else {
                rv = 0;
            }
            break;

        case EVFILT_TIMER:
            //TODO
            rv = -1;
            break;

        default:
            rv = -1;
            return (-1);
    }

//    if (rv < 0)
//        free(evcopy);
    return (rv);
}

/* Delete an item from the list of events to be monitored */
static int
kq_delete(kqueue_t kq, const struct kevent *ev)
{
    int rv = 0;
    int sigfd;
    struct epoll_event epev;

    switch (ev->ident) {
        case EVFILT_READ:
        case EVFILT_WRITE:
            rv = epoll_ctl(kq->epfd, EPOLL_CTL_DEL, ev->ident, &epev);
            break;

        case EVFILT_VNODE:
            //TODO
            break;

        case EVFILT_SIGNAL:
            kq_lock(kq);
            sigdelset(&kq->sigmask, ev->ident);
            sigfd = signalfd(kq->wfd[EVFILT_SIGNAL], &kq->sigmask, 0);
            kq_unlock(kq);
            if (sigfd < 0) {
                rv = -1;
            } else {
                rv = 0;
            }
            break;

        case EVFILT_TIMER:
            //TODO
            break;

        default:
            rv = 0;
            break;
    }
    return (rv);
}

#endif /* defined(USE_EPOLL) */

/* Equivalent to kevent() */
int kq_event(kqueue_t kq, const struct kevent *changelist, int nchanges,
	    struct kevent *eventlist, int nevents,
	    const struct timespec *timeout)
{
    int rv = 0;
    struct kevent *kevp, *dst;

#if defined(USE_KQUEUE)
    return kevent(kq->kqfd, changelist, nchanges, eventlist, nevents, timeout);

#elif defined(USE_EPOLL)
    struct epoll_event epev_buf[EPEV_BUF_MAX];
    struct epoll_event *epev;
    size_t epev_wait_max, epev_cnt;
    int i, eptimeout;

    /* Process each item on the changelist */
    for (i = 0; i < nchanges; i++) {
        if (changelist[i].flags & EV_ADD) {
            rv = kq_add(kq, &changelist[i]);
        } else if (changelist[i].flags & EV_DELETE) {
            rv = kq_delete(kq, &changelist[i]);
        } else {
            rv = -1;
        }
        if (rv < 0)
            return (-1);
    }

    /* Convert timeout to the format used by epoll_wait() */
    if (timeout == NULL) 
        eptimeout = -1;
    else
        eptimeout = (1000 * timeout->tv_sec) + (timeout->tv_nsec / 1000000);

    /* Wait for events and put them into a buffer */
    if (nevents > EPEV_BUF_MAX) {
        epev_wait_max = EPEV_BUF_MAX;
    } else {
        epev_wait_max = nevents;
    }
    epev_cnt = epoll_wait(kq->epfd, (struct epoll_event *) &epev_buf, epev_wait_max, eptimeout);
    if (epev_cnt < 0) {
        return (-1);        //FIXME: handle timeout
    }

    /* Determine what events have occurred and copy the result to the caller */
    for (i = 0; i < epev_cnt; i++) {
        dst = &eventlist[i];
        epev = &epev_buf[i];

        /*
           epev->data.u32 is an index into kq->kev that stores
           a copy of the kevent structure.
         */
        kevp = (struct kevent *) utarray_eltptr(kq->kev, epev->data.u32);

        /* Some filters require an extra level of indirection to get at
           the real kevent. */
        switch (kevp->ident) {
            case EVFILT_SIGNAL:
                //TODO
                break;

            case EVFILT_VNODE:
                //TODO
                break;

            case EVFILT_TIMER:
                //TODO
                break;

            case EVFILT_READ:
            case EVFILT_WRITE:
                memcpy(dst, kevp, sizeof(*dst));
                break;

            default:
                abort();
        }
    }

    return (rv == 1 ? 0 : -1);
#endif
}
