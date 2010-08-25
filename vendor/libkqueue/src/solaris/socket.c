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

static int
socket_knote_create(int port, int filter, int fd, void *udata)
{
    int rv, events;

    switch (filter) {
        case EVFILT_READ:
                events = POLLIN;
                break;
        case EVFILT_WRITE:
                events = POLLOUT;
                break;
        default:
                dbg_puts("invalid filter");
                return (-1);
    }

    rv = port_associate(port, PORT_SOURCE_FD, fd, events, udata);
    if (rv < 0) {
            dbg_perror("port_associate(2)");
            return (-1);
        }

    return (0);
}

static int
socket_knote_delete(int port, int fd)
{
   if (port_dissociate(port, PORT_SOURCE_FD, fd) < 0) {
            dbg_perror("port_dissociate(2)");
            return (-1);
   } else {
	return (0);
   }
}
   
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
            dbg_perror("port_dissociate(2)");
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
    return socket_knote_create(filt->kf_kqueue->kq_port,
		kn->kev.filter, kn->kev.ident, kn->kev.udata);
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
    if (kn->kev.flags & EV_DISABLE)
        return (0);
    else
        return (socket_knote_delete(filt->kf_kqueue->kq_port, kn->kev.ident));
}

int
evfilt_socket_knote_enable(struct filter *filt, struct knote *kn)
{
    return socket_knote_create(filt->kf_kqueue->kq_port,
		kn->kev.filter, kn->kev.ident, kn->kev.udata);
}

int
evfilt_socket_knote_disable(struct filter *filt, struct knote *kn)
{
    return socket_knote_delete(filt->kf_kqueue->kq_port, kn->kev.ident);
}

int
evfilt_socket_copyout(struct filter *filt, 
            struct kevent *dst, 
            int nevents)
{
    port_event_t *pe = (port_event_t *) pthread_getspecific(filt->kf_kqueue->kq_port_event);
    struct knote *kn;

    kn = knote_lookup(filt, pe->portev_object);
    if (kn == NULL)
	return (-1);

    memcpy(dst, &kn->kev, sizeof(*dst));
    if (pe->portev_events & POLLHUP)
        dst->flags |= EV_EOF;
    if (pe->portev_events & POLLERR)
        dst->fflags = 1; /* FIXME: Return the actual socket error */
          
    if (kn->flags & KNFL_PASSIVE_SOCKET) {
        /* On return, data contains the length of the 
           socket backlog. This is not available under Solaris (?).
         */
        dst->data = 1;
    } else {
        /* On return, data contains the number of bytes of protocol
           data available to read.
         */
#if FIXME
        if (ioctl(dst->ident, 
                    (dst->filter == EVFILT_READ) ? SIOCINQ : SIOCOUTQ, 
                            &dst->data) < 0) {
                  /* race condition with socket close, so ignore this error */
                    dbg_puts("ioctl(2) of socket failed");
                    dst->data = 0;
     	}
#else
                    dst->data = 1;
#endif
    }

    if (kn->kev.flags & EV_DISPATCH) {
        socket_knote_delete(filt->kf_kqueue->kq_port, kn->kev.ident);
        KNOTE_DISABLE(kn);
    } else if (kn->kev.flags & EV_ONESHOT) {
        socket_knote_delete(filt->kf_kqueue->kq_port, kn->kev.ident);
        knote_free(filt, kn);
    } else {
	/* Solaris automatically disassociates a FD event after it
	   is delivered. This effectively disables the knote. */
        KNOTE_DISABLE(kn);
    }

    return (1);
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
