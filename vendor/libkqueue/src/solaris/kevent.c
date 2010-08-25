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

#include <stdlib.h>
#include <port.h>

#include "sys/event.h"
#include "private.h"

static char *
port_event_dump(port_event_t *evt)
{
    static char __thread buf[512];

    if (evt == NULL)
        return "(null)";

#define PE_DUMP(attrib) \
    if (evt->portev_source == attrib) \
       strcat(&buf[0], #attrib);

    snprintf(&buf[0], 512,
                " { object = %u, user = %p, events = 0x%o, source = %d (",
                (unsigned int) evt->portev_object,
                evt->portev_user,
                evt->portev_events,
                evt->portev_source);
    PE_DUMP(PORT_SOURCE_AIO);
    PE_DUMP(PORT_SOURCE_FD);
    PE_DUMP(PORT_SOURCE_TIMER);
    PE_DUMP(PORT_SOURCE_USER);
    PE_DUMP(PORT_SOURCE_ALERT);
    strcat(&buf[0], ") }\n");

    return (&buf[0]);
#undef PE_DUMP
}

int
kevent_wait(struct kqueue *kq, const struct timespec *timeout)
{
    port_event_t *pe = (port_event_t *) pthread_getspecific(kq->kq_port_event);
    int rv;

    dbg_printf("waiting for events (timeout=%p)", timeout);
    memset(pe, 0, sizeof(*pe));
    rv = port_get(kq->kq_port, pe, (struct timespec *) timeout);
    dbg_printf("rv=%d errno=%d evt=%s",rv,errno,
                port_event_dump(pe));
    if (rv < 0) {
        if (errno == ETIME) {
            dbg_puts("no events within the given timeout");
            return (0);
        }
        if (errno == EINTR) {
            dbg_puts("signal caught");
            return (-1);
        }
        dbg_perror("port_get(2)");
        return (-1);
    }
    if (rv < 0) {
        if (errno == ETIME) {
            dbg_puts("no events within the given timeout");
            return (0);
        }
        if (errno == EINTR) {
            dbg_puts("signal caught");
            return (-1);
        }
        dbg_perror("port_get(2)");
        return (-1);
    }

    /* UNDOCUMENTED: polling a port with no associated events
         does not return -1 and ETIME. Instead it seems to return
         0 and pe->portev_source == 0
    */
    if (pe->portev_source == 0)
       return (0);

    return (1);
}

int
kevent_copyout(struct kqueue *kq, int nready,
        struct kevent *eventlist, int nevents)
{
    port_event_t *pe = (port_event_t *) pthread_getspecific(kq->kq_port_event);
    struct filter *filt;
    int rv;

    dbg_printf("%s", port_event_dump(pe));
    switch (pe->portev_source) {
	case PORT_SOURCE_FD:
		//FIXME: could also be EVFILT_WRITE
        	filter_lookup(&filt, kq, EVFILT_READ);
                rv = filt->kf_copyout(filt, eventlist, nevents);
		break;
	default:
		dbg_puts("unsupported source");
    		abort();
    }
    if (rv < 0) {
        dbg_puts("kevent_copyout failed");
	return (-1);
    }

    return (1);
}
