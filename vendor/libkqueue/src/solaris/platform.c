/*
 * Copyright (c) 2011 Mark Heily <mark@heily.com>
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

#include "../common/private.h"

const struct filter evfilt_vnode = EVFILT_NOTIMPL;
const struct filter evfilt_proc  = EVFILT_NOTIMPL;

static char * port_event_dump(port_event_t *evt);

/*
 * Per-thread port event buffer used to ferry data between
 * kevent_wait() and kevent_copyout().
 */
static port_event_t __thread evbuf[MAX_KEVENT];

int
solaris_kqueue_init(struct kqueue *kq)
{
    if (posix_kqueue_init(kq) < 0)
        return (-1);
    if ((kq->kq_port = port_create()) < 0) {
        dbg_perror("port_create(2)");
        return (-1);
    }
    dbg_printf("created event port; fd=%d", kq->kq_port);
    TAILQ_INIT(&kq->kq_events);
    return (0);
}

void
solaris_kqueue_free(struct kqueue *kq)
{
    posix_kqueue_free(kq);
    if (kq->kq_port > 0) {
        (void) close(kq->kq_port);
        dbg_printf("closed event port; fd=%d", kq->kq_port);
    }
}

/* Dump a poll(2) events bitmask */
static char *
poll_events_dump(short events)
{
    static char __thread buf[512];

#define _PL_DUMP(attrib) \
    if (events == attrib) \
       strcat(&buf[0], " "#attrib);

    snprintf(&buf[0], 512, "events = %hd 0x%o (", events, events);
    _PL_DUMP(POLLIN);
    _PL_DUMP(POLLPRI);
    _PL_DUMP(POLLOUT);
    _PL_DUMP(POLLRDNORM);
    _PL_DUMP(POLLRDBAND);
    _PL_DUMP(POLLWRBAND);
    _PL_DUMP(POLLERR);
    _PL_DUMP(POLLHUP);
    _PL_DUMP(POLLNVAL);
    strcat(&buf[0], ")");

    return (&buf[0]);

#undef _PL_DUMP
}

static char *
port_event_dump(port_event_t *evt)
{
    static char __thread buf[512];

    if (evt == NULL) {
        snprintf(&buf[0], sizeof(buf), "NULL ?!?!\n");
        goto out;
    }

#define PE_DUMP(attrib) \
    if (evt->portev_source == attrib) \
       strcat(&buf[0], #attrib);

    snprintf(&buf[0], 512,
                " { object = %u, user = %p, %s, source = %d (",
                (unsigned int) evt->portev_object,
                evt->portev_user,
                poll_events_dump(evt->portev_events),
                evt->portev_source);
    PE_DUMP(PORT_SOURCE_AIO);
    PE_DUMP(PORT_SOURCE_FD);
    PE_DUMP(PORT_SOURCE_TIMER);
    PE_DUMP(PORT_SOURCE_USER);
    PE_DUMP(PORT_SOURCE_ALERT);
    strcat(&buf[0], ") }\n");
#undef PE_DUMP

out:
    return (&buf[0]);
}

int
solaris_kevent_wait(
        struct kqueue *kq, 
        int nevents,
        const struct timespec *ts)

{
    port_event_t pe;
    int rv;
    uint_t nget = 1;

    reset_errno();
    dbg_puts("waiting for events");
    rv = port_getn(kq->kq_port, &evbuf[0], 1, &nget, (struct timespec *) ts);
    dbg_printf("rv=%d errno=%d (%s) nget=%d", 
                rv, errno, strerror(errno), nget);
    if (rv < 0) {
        if (errno == ETIME) {
            dbg_puts("no events within the given timeout");
            return (0);
        }
        if (errno == EINTR) {
            dbg_puts("signal caught");
            return (-1);
        }
        dbg_perror("port_getn(2)");
        return (-1);
    }

    return (nget);
}

int
solaris_kevent_copyout(struct kqueue *kq, int nready,
        struct kevent *eventlist, int nevents)
{
    port_event_t  *evt;
    struct filter *filt;
    int i, rv;

    for (i = 0; i < nready; i++) {
        evt = &evbuf[i];
        dbg_printf("event=%s", port_event_dump(evt));
        switch (evt->portev_source) {
            case PORT_SOURCE_FD:
                filt = evt->portev_user;
                rv = filt->kf_copyout(filt, eventlist, nevents);
                break;

            case PORT_SOURCE_TIMER:
                filter_lookup(&filt, kq, EVFILT_TIMER);
                rv = filt->kf_copyout(filt, eventlist, nevents);
                break;

            case PORT_SOURCE_USER:
                switch (ebp->pe.portev_events) {
                    case X_PORT_SOURCE_SIGNAL:
                        filter_lookup(&filt, kq, EVFILT_SIGNAL);
                        rv = filt->kf_copyout(filt, eventlist, nevents);
                        break;
                    case X_PORT_SOURCE_USER:
                        filter_lookup(&filt, kq, EVFILT_USER);
                        rv = filt->kf_copyout(filt, eventlist, nevents);
                        break;
                    default:
                dbg_puts("unsupported portev_events");
                abort();
                }
                break;

            default:
                dbg_puts("unsupported source");
                abort();
        }
    if (rv < 0) {
        dbg_puts("kevent_copyout failed");
	return (-1);
    }
    }

    return (nready);
}

const struct kqueue_vtable kqops =
{
    solaris_kqueue_init,
    solaris_kqueue_free,
    solaris_kevent_wait,
    solaris_kevent_copyout,
    NULL,
    NULL,
    posix_eventfd_init,
    posix_eventfd_close,
    posix_eventfd_raise,
    posix_eventfd_lower,
    posix_eventfd_descriptor
};
