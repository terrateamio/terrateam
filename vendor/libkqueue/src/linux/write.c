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
evfilt_write_copyout(struct kevent *dst, struct knote *src, void *ptr)
{
    int ret;
    int serr;
    socklen_t slen = sizeof(serr);
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
    if (ev->events & EPOLLERR) {
        if (src->kn_flags & KNFL_SOCKET) {
            ret = getsockopt(src->kev.ident, SOL_SOCKET, SO_ERROR, &serr, &slen);
            dst->fflags = ((ret < 0) ? errno : serr);
        } else { dst->fflags = EIO; }
    }

    /* On return, data contains the the amount of space remaining in the write buffer */
    if (ioctl(dst->ident, SIOCOUTQ, &dst->data) < 0) {
            /* race condition with socket close, so ignore this error */
            dbg_puts("ioctl(2) of socket failed");
            dst->data = 0;
    }

    return (0);
}

int
evfilt_write_knote_create(struct filter *filt, struct knote *kn)
{
    struct epoll_event ev;

    if (linux_get_descriptor_type(kn) < 0)
        return (-1);

    if (kn->kn_flags & KNFL_FILE) {
        errno = EBADF;
        return (-1);
    }

    /* Convert the kevent into an epoll_event */
    kn->data.events = EPOLLOUT;
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
evfilt_write_knote_modify(struct filter *filt, struct knote *kn,
        const struct kevent *kev)
{
    (void) filt;
    (void) kn;
    (void) kev;
    return (-1); /* STUB */
}

int
evfilt_write_knote_delete(struct filter *filt, struct knote *kn)
{
    if (kn->kev.flags & EV_DISABLE)
        return (0);
    else
        return epoll_update(EPOLL_CTL_DEL, filt, kn, NULL);
}

int
evfilt_write_knote_enable(struct filter *filt, struct knote *kn)
{
    struct epoll_event ev;

    memset(&ev, 0, sizeof(ev));
    ev.events = kn->data.events;
    ev.data.ptr = kn;

    return epoll_update(EPOLL_CTL_ADD, filt, kn, &ev);
}

int
evfilt_write_knote_disable(struct filter *filt, struct knote *kn)
{
    return epoll_update(EPOLL_CTL_DEL, filt, kn, NULL);
}

const struct filter evfilt_write = {
    .kf_id      = EVFILT_WRITE,
    .kf_copyout = evfilt_write_copyout,
    .kn_create  = evfilt_write_knote_create,
    .kn_modify  = evfilt_write_knote_modify,
    .kn_delete  = evfilt_write_knote_delete,
    .kn_enable  = evfilt_write_knote_enable,
    .kn_disable = evfilt_write_knote_disable,
};
