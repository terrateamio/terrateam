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
#include <string.h>

#include "sys/event.h"
#include "private.h"

#define PORTEV_DUMP(pe) dbg_printf("port_event: events=%d source=%hu", \
        (pe)->portev_events, (pe)->portev_source)
int
kqueue_init_hook(void)
{
    return (0);
}

int
kqueue_hook(struct kqueue *kq)
{
    if ((kq->kq_port = port_create()) < 0) {
        dbg_perror("port_create(2)");
        return (-1);
    }

    return (0);
}
 
int
kevent_wait(struct kqueue *kq, const struct timespec *timeout)
{
    port_event_t pe[1];
    int rv, nget;

    dbg_printf("port_get: %d %lu %lu", 
            kq->kq_port, timeout->tv_sec, timeout->tv_nsec);
    nget = 1;
    rv = port_getn(kq->kq_port, pe, 1, &nget, (struct timespec *) timeout);
    if (rv < 0) {
        if (errno == EINTR) {
            dbg_puts("signal caught");
            return (-1);
        }
        dbg_perror("port_getn(2)");
        return (-1);
    }
    if (nget > 0) {
        dbg_printf("  -- event(s) pending: nget = %d", nget);
        PORTEV_DUMP(&pe[0]);
    } else {
        dbg_puts("  -- no events --");
    }

    return (nget);
}   

int
kevent_copyout(struct kqueue *kq, int nready,
        struct kevent *eventlist, int nevents)
{
    return (-1);
#if TODO
    struct filter *filt;
    int i, rv, nret;

    if (FD_ISSET(filt->kf_pfd, &kq->kq_rfds)) {
            dbg_printf("event(s) for filter #%d", i);
            filter_lock(filt);
            rv = filt->kf_copyout(filt, eventlist, nevents);
            if (rv < 0) {
                filter_unlock(filt);
                dbg_puts("kevent_copyout failed");
                return (-1);
            }
            nret += rv;
            eventlist += rv;
            nevents -= rv;
            nready--;
            filter_unlock(filt);
        }

    return (nret);
#endif
}
