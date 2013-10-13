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

#ifndef  _KQUEUE_LITE_H
#define  _KQUEUE_LITE_H

#if defined(__FreeBSD__) || defined(
#define USE_KQUEUE
#elif defined(__linux__)
#define USE_EPOLL
#else
#error Unsupported operating system type
#endif

/* Define an object that represents the event descriptor */
struct event_source {
#if USE_KQUEUE
    int kqfd;            /* kqueue */
#elif USE_EPOLL
    /* Linux has a separate file descriptor for each event type. */
    int epfd;            /* epoll */
    int inofd;           /* inotify */
    int timefd;          /* timerfd */
    int sigfd;           /* signalfd */
#endif
};

/* Initialize the event descriptor */
static inline int
event_source_init(struct event_source *ev)
{
#if USE_KQUEUE
    // ev = kqueue()
#elif USE_EPOLL
    // ev = epoll_create
    // inofd = inotify_create
    // timefd = timerfd_create
    // sigfd = sigfd_create
    // add inofd, timed, sigfd, to ev
#endif
    return (0);
}

// TODO: event_listen()
// TODO: event_get()

/* Avoid polluting the namespace of the calling program */
#ifdef USE_KQUEUE
#undef USE_KQUEUE
#endif
#ifdef USE_EPOLL
#undef USE_EPOLL
#endif

#endif  /* ! _KQUEUE_LITE_H */
