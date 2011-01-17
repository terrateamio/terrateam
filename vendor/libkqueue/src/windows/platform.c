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

/* FIXME: remove these as filters are implemented */
const struct filter evfilt_proc = EVFILT_NOTIMPL;
const struct filter evfilt_vnode = EVFILT_NOTIMPL;
const struct filter evfilt_signal = EVFILT_NOTIMPL;
const struct filter evfilt_write = EVFILT_NOTIMPL;
const struct filter evfilt_read = EVFILT_NOTIMPL;
const struct filter evfilt_timer = EVFILT_NOTIMPL;
const struct filter evfilt_user = EVFILT_NOTIMPL;

BOOL WINAPI DllMain(
        HINSTANCE self,
        DWORD reason,
        LPVOID unused)
{
    switch (reason) { 
        case DLL_PROCESS_ATTACH:

#if XXX
			//move to EVFILT_READ?
            if (WSAStartup(MAKEWORD(2,2), NULL) != 0)
                return (FALSE);
#endif
			if (_libkqueue_init() < 0)
				return (FALSE);
            /* TODO: bettererror handling */
            break;

        case DLL_PROCESS_DETACH:
            WSACleanup();
            break;
    }

    return (TRUE);
}

int
windows_kqueue_init(struct kqueue *kq)
{
    kq->kq_handle = CreateEvent(NULL, FALSE, FALSE, NULL);
    if (kq->kq_handle == NULL) {
        dbg_perror("CreatEvent()");
        return (-1);
    }

    return (0);
}

void
windows_kqueue_free(struct kqueue *kq)
{
    CloseHandle(kq->kq_handle);
    free(kq);
}


int
windows_kevent_wait(struct kqueue *kq, const struct timespec *timeout)
{
#if FIXME
    port_event_t pe;
    int rv;
    uint_t nget = 1;

    reset_errno();
    dbg_printf("waiting for events (timeout=%p)", timeout);
    rv = port_getn(kq->kq_port, &pe, 1, &nget, (struct timespec *) timeout);
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
        dbg_perror("port_get(2)");
        return (-1);
    }

    port_event_enqueue(kq, &pe);

    return (nget);
#endif
	return 0;
}

int
windows_kevent_copyout(struct kqueue *kq, int nready,
        struct kevent *eventlist, int nevents)
{
#if FIXME
    struct event_buf *ebp;
    struct filter *filt;
    int rv;

    ebp = TAILQ_FIRST(&kq->kq_events);
    if (ebp == NULL) {
        dbg_puts("kq_events was empty");
        return (-1);
    }

    dbg_printf("event=%s", port_event_dump(&ebp->pe));
    switch (ebp->pe.portev_source) {
	case PORT_SOURCE_FD:
        filt = ebp->pe.portev_user;
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

#endif
    return (1);
}

