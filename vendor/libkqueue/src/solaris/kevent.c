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

/* KLUDGE: This avoids the need to redesign the POSIX code */
static __thread port_event_t pe;

static char *
port_event_dump(port_event_t *evt)
{
    static char __thread buf[128];

    if (evt == NULL)
        return "(null)";

#define PE_DUMP(attrib) \
    if (evt->portev_source == attrib) \
       strcat(&buf[0], #attrib" ");

    snprintf(&buf[0], 128,
                " { object = %u, user = %p, events = %d, source = %d",
                (unsigned int) evt->portev_object,
                evt->portev_user,
                evt->portev_events,
                evt->portev_source);
    PE_DUMP(PORT_SOURCE_AIO);
    PE_DUMP(PORT_SOURCE_FD);
    PE_DUMP(PORT_SOURCE_TIMER);
    PE_DUMP(PORT_SOURCE_USER);
    PE_DUMP(PORT_SOURCE_ALERT);
    strcat(&buf[0], "}\n");

    return (&buf[0]);
#undef PE_DUMP
}

int
kevent_wait(struct kqueue *kq, const struct timespec *timeout)
{
    int rv;

    dbg_printf("waiting for events (timeout=%p)", timeout);
    memset(&pe, 0, sizeof(pe));
    rv = port_get(kq->kq_port, &pe, (struct timespec *) timeout);
    dbg_printf("rv=%d errno=%d evt=%s",rv,errno,
                port_event_dump(&pe));
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
    if (pe.portev_source == 0)
       return (0);

    return (1);
}

int
kevent_copyout(struct kqueue *kq, int nready,
        struct kevent *eventlist, int nevents)
{
    struct filter *filt;
    int i, rv, nret;

    nret = 0;
    for (i = 0; (i < EVFILT_SYSCOUNT && nready > 0 && nevents > 0); i++) {
//        dbg_printf("eventlist: n = %d nevents = %d", nready, nevents);
        filt = &kq->kq_filt[i]; 
//        dbg_printf("pfd[%d] = %d", i, filt->kf_pfd);
        if (FD_ISSET(filt->kf_pfd, &kq->kq_rfds)) {
            dbg_printf("pending events for filter %d (%s)", filt->kf_id, filter_name(filt->kf_id));
            rv = filt->kf_copyout(filt, eventlist, nevents);
            if (rv < 0) {
                dbg_puts("kevent_copyout failed");
                nret = -1;
                break;
            }
            nret += rv;
            eventlist += rv;
            nevents -= rv;
            nready--;
        }
    }

    return (nret);
}
