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
#include <linux/sockios.h>
#include <pthread.h>
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/ioctl.h>
#include <sys/queue.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <string.h>
#include <unistd.h>

#include "private.h"

int
evfilt_read_copyout(struct kevent *dst, struct knote *src, void *ptr)
{
    struct epoll_event * const ev = (struct epoll_event *) ptr;

    epoll_event_dump(ev);
    memcpy(dst, &src->kev, sizeof(*dst));
#if defined(HAVE_EPOLLRDHUP)
    if (ev->events & EPOLLRDHUP || ev->events & EPOLLHUP)
        dst->flags |= EV_EOF;
#else
    if (ev->events & EPOLLHUP)
        dst->flags |= EV_EOF;
#endif
    if (ev->events & EPOLLERR)
        dst->fflags = 1; /* FIXME: Return the actual socket error */
          
    if (src->flags & KNFL_PASSIVE_SOCKET) {
        /* On return, data contains the length of the 
           socket backlog. This is not available under Linux.
         */
        dst->data = 1;
    } else {
        /* On return, data contains the number of bytes of protocol
           data available to read.
         */
        if (ioctl(dst->ident, SIOCINQ, &dst->data) < 0) {
            /* race condition with socket close, so ignore this error */
            dbg_puts("ioctl(2) of socket failed");
            dst->data = 0;
        }
    }

    return (0);
}

int
evfilt_read_knote_create(struct filter *filt, struct knote *kn)
{
    struct epoll_event ev;

    if (linux_get_descriptor_type(kn) < 0)
        return (-1);

    /* Convert the kevent into an epoll_event */
#if defined(HAVE_EPOLLRDHUP)
    kn->data.events = EPOLLIN | EPOLLRDHUP;
#else
    kn->data.events = EPOLLIN;
#endif
    if (kn->kev.flags & EV_ONESHOT || kn->kev.flags & EV_DISPATCH)
        kn->data.events |= EPOLLONESHOT;
    if (kn->kev.flags & EV_CLEAR)
        kn->data.events |= EPOLLET;

    memset(&ev, 0, sizeof(ev));
    ev.events = kn->data.events;
    ev.data.ptr = kn;

    return epoll_update(EPOLL_CTL_ADD, filt, kn, &ev);
}

int
evfilt_read_knote_modify(struct filter *filt, struct knote *kn, 
        const struct kevent *kev)
{
    return (-1); /* STUB */
}

int
evfilt_read_knote_delete(struct filter *filt, struct knote *kn)
{
    if (kn->kev.flags & EV_DISABLE)
        return (0);
    else
        return epoll_update(EPOLL_CTL_DEL, filt, kn, NULL);
}

int
evfilt_read_knote_enable(struct filter *filt, struct knote *kn)
{
    struct epoll_event ev;

    memset(&ev, 0, sizeof(ev));
    ev.events = kn->data.events;
    ev.data.ptr = kn;

    return epoll_update(EPOLL_CTL_ADD, filt, kn, &ev);
}

int
evfilt_read_knote_disable(struct filter *filt, struct knote *kn)
{
    return epoll_update(EPOLL_CTL_DEL, filt, kn, NULL);
}

const struct filter evfilt_read = {
    EVFILT_READ,
    NULL,
    NULL,
    evfilt_read_copyout,
    evfilt_read_knote_create,
    evfilt_read_knote_modify,
    evfilt_read_knote_delete,
    evfilt_read_knote_enable,
    evfilt_read_knote_disable,         
};
