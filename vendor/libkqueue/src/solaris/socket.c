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
#include <sys/queue.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <string.h>
#include <unistd.h>

#include <port.h>

#include "sys/event.h"
#include "private.h"

int
evfilt_socket_init(struct filter *filt)
{
    return (0);
}

void
evfilt_socket_destroy(struct filter *filt)
{
    ;
}

#if DEADWOOD
// split into multiple funcs
int
evfilt_socket_copyin(struct filter *filt, 
        struct knote *dst, const struct kevent *src)
{
    int port, events;
    int rv;

    port = filt->kf_kqueue->kq_port;

    /* Not supported or not implemented */
    if (src->flags & EV_CLEAR) {
        dbg_puts("attempt to use unsupported mechanism");
        return (-1);
    }

    if (src->filter == EVFILT_READ)
        events = POLLIN;
    else
        events = POLLOUT;

    if (src->flags & EV_DELETE || src->flags & EV_DISABLE) {
        rv = port_dissociate(port, PORT_SOURCE_FD, src->ident);
        if (rv < 0) {
            dbg_perror("port_disassociate(2)");
            return (-1);
        }
    }
    if (src->flags & EV_ENABLE || src->flags & EV_ADD) {
        rv = port_associate(port, PORT_SOURCE_FD, 
                src->ident, events, src->udata);
        if (rv < 0) {
            dbg_perror("port_associate(2)");
            return (-1);
        }
    }
    /* XXX-TODO support modifying an existing watch */

    return (0);
}
#endif

int
evfilt_socket_knote_create(struct filter *filt, struct knote *kn)
{
#if TODO
    struct epoll_event ev;

    /* Convert the kevent into an epoll_event */
    if (kn->kev.filter == EVFILT_READ)
        kn->kn_events = EPOLLIN | EPOLLRDHUP;
    else
        kn->kn_events = EPOLLOUT;
    if (kn->kev.flags & EV_ONESHOT || kn->kev.flags & EV_DISPATCH)
        kn->kn_events |= EPOLLONESHOT;
    if (kn->kev.flags & EV_CLEAR)
        kn->kn_events |= EPOLLET;

    memset(&ev, 0, sizeof(ev));
    ev.events = kn->kn_events;
    ev.data.fd = kn->kev.ident;

    return epoll_update(EPOLL_CTL_ADD, filt, kn, &ev);
#endif
	return (-1);
}

int
evfilt_socket_knote_modify(struct filter *filt, struct knote *kn, 
        const struct kevent *kev)
{
    return (-1); /* STUB */
}

int
evfilt_socket_knote_delete(struct filter *filt, struct knote *kn)
{
#if TODO
    if (kn->kev.flags & EV_DISABLE)
        return (0);
    else
        return epoll_update(EPOLL_CTL_DEL, filt, kn, NULL);
#else
   return (-1);
#endif
}

int
evfilt_socket_knote_enable(struct filter *filt, struct knote *kn)
{
#if TODO
    struct epoll_event ev;

    memset(&ev, 0, sizeof(ev));
    ev.events = kn->kn_events;
    ev.data.fd = kn->kev.ident;

    return epoll_update(EPOLL_CTL_ADD, filt, kn, &ev);
#else
   return (-1);
#endif
}

int
evfilt_socket_knote_disable(struct filter *filt, struct knote *kn)
{
#if TODO
    return epoll_update(EPOLL_CTL_DEL, filt, kn, NULL);
#else
   return (-1);
#endif
}

int
evfilt_socket_copyout(struct filter *filt, 
            struct kevent *dst, 
            int nevents)
{
    return (-1);
}

const struct filter evfilt_read = {
    EVFILT_READ,
    evfilt_socket_init,
    evfilt_socket_destroy,
    evfilt_socket_copyout,
    evfilt_socket_knote_create,
    evfilt_socket_knote_modify,
    evfilt_socket_knote_delete,
    evfilt_socket_knote_enable,
    evfilt_socket_knote_disable,         
};

const struct filter evfilt_write = {
    EVFILT_WRITE,
    evfilt_socket_init,
    evfilt_socket_destroy,
    evfilt_socket_copyout,
    evfilt_socket_knote_create,
    evfilt_socket_knote_modify,
    evfilt_socket_knote_delete,
    evfilt_socket_knote_enable,
    evfilt_socket_knote_disable,         
};
