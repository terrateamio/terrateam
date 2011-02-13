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
evfilt_socket_knote_create(struct filter *filt, struct knote *kn)
{
    int rv, events;

    switch (kn->kev.filter) {
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

    rv = port_associate(filter_epfd(filt), PORT_SOURCE_FD, kn->kev.ident, 
            events, kn);
    if (rv < 0) {
            dbg_perror("port_associate(2)");
            return (-1);
        }

    return (0);
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
        return (socket_knote_delete(filter_epfd(filt), kn->kev.ident));
}

int
evfilt_socket_knote_enable(struct filter *filt, struct knote *kn)
{
    return socket_knote_create(filter_epfd(filt),
		kn->kev.filter, kn->kev.ident, filt);
}

int
evfilt_socket_knote_disable(struct filter *filt, struct knote *kn)
{
    return socket_knote_delete(filter_epfd(filt), kn->kev.ident);
}

int
evfilt_socket_copyout(struct kevent *dst, struct knote *src, void *ptr)
{
    port_event_t *pe = (port_event_t *) ptr;

    memcpy(dst, &src->kev, sizeof(*dst));
    if (pe->portev_events == 8) //XXX-FIXME Should be POLLHUP)
        dst->flags |= EV_EOF;
    else if (pe->portev_events & POLLERR)
        dst->fflags = 1; /* FIXME: Return the actual socket error */
          
    if (pe->portev_events & POLLIN) {
        if (src->flags & KNFL_PASSIVE_SOCKET) {
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
            /* Workaround */
            dst->data = 1;
#endif
        }
    }

    /* FIXME: make sure this is in kqops.copyout() 
    if (src->kev.flags & EV_DISPATCH || src->kev.flags & EV_ONESHOT) {
        socket_knote_delete(filt->kf_kqueue->kq_port, kn->kev.ident);
    }
    */

    return (1);
}

const struct filter evfilt_read = {
    EVFILT_READ,
    NULL,
    NULL,
    evfilt_socket_copyout,
    evfilt_socket_knote_create,
    evfilt_socket_knote_modify,
    evfilt_socket_knote_delete,
    evfilt_socket_knote_enable,
    evfilt_socket_knote_disable,         
};

const struct filter evfilt_write = {
    EVFILT_WRITE,
    NULL,
    NULL,
    evfilt_socket_copyout,
    evfilt_socket_knote_create,
    evfilt_socket_knote_modify,
    evfilt_socket_knote_delete,
    evfilt_socket_knote_enable,
    evfilt_socket_knote_disable,         
};
