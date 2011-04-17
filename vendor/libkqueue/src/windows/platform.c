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

/*
 * Per-thread evt event buffer used to ferry data between
 * kevent_wait() and kevent_copyout().
 */
static struct evt_event_s __thread pending_events[MAX_KEVENT];

/* FIXME: remove these as filters are implemented */
const struct filter evfilt_proc = EVFILT_NOTIMPL;
const struct filter evfilt_vnode = EVFILT_NOTIMPL;
const struct filter evfilt_signal = EVFILT_NOTIMPL;
const struct filter evfilt_write = EVFILT_NOTIMPL;
const struct filter evfilt_read = EVFILT_NOTIMPL;
const struct filter evfilt_user = EVFILT_NOTIMPL;

const struct kqueue_vtable kqops = {
    windows_kqueue_init,
    windows_kqueue_free,
	windows_kevent_wait,
	windows_kevent_copyout,
	windows_filter_init,
	windows_filter_free,
};

#ifndef MAKE_STATIC

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
            if (libkqueue_init() < 0)
				return (FALSE);
            break;

        case DLL_PROCESS_DETACH:
#if XXX
            WSACleanup();
#endif
            break;
    }

    return (TRUE);
}

#endif

int
windows_kqueue_init(struct kqueue *kq)
{
    kq->kq_loop = evt_create();
    if (kq->kq_loop == NULL) {
        dbg_perror("evt_create()");
        return (-1);
    }

	if(filter_register_all(kq) < 0) {
		evt_destroy(kq->kq_loop);
		return (-1);
	}

    return (0);
}

void
windows_kqueue_free(struct kqueue *kq)
{
    evt_destroy(kq->kq_loop);
    free(kq);
}

int
windows_kevent_wait(struct kqueue *kq, int no, const struct timespec *timeout)
{
	int retval;
    DWORD rv, timeout_ms;
    
	/* Convert timeout to milliseconds */
	/* NOTE: loss of precision for timeout values less than 1ms */
	if (timeout == NULL) {
		timeout_ms = INFINITE;
	} else {
		timeout_ms = 0;
		if (timeout->tv_sec > 0)
			timeout_ms += ((DWORD)timeout->tv_sec) / 1000;
		if (timeout->tv_sec > 0)
			timeout_ms += timeout->tv_nsec / 1000000;
	}

	/* Wait for an event */
    dbg_printf("waiting for %u events (timeout=%u ms)", kq->kq_filt_count, (unsigned int)timeout_ms);
	rv = evt_run(kq->kq_loop, pending_events, MAX_KEVENT, timeout); 
	switch (rv) {
	case EVT_TIMEDOUT:
		dbg_puts("no events within the given timeout");
		retval = 0;
		break;

	case EVT_ERR:
		dbg_lasterror("WaitForSingleEvent()");
		retval = -1;

	default:
		retval = rv;
	}
	
    return (retval);
}

int
windows_kevent_copyout(struct kqueue *kq, int nready,
        struct kevent *eventlist, int nevents)
{
    struct filter *filt;
	struct knote* kn;
	evt_event_t evt;
    int i, rv, nret;

	assert(nready < MAX_KEVENT);

	nret = nready;
	for(i = 0; i < nready; i++) {
		evt = &(pending_events[i]);
		kn = (struct knote*)evt->data;
		knote_lock(kn);
		filt = &kq->kq_filt[~(kn->kev.filter)];
		rv = filt->kf_copyout(eventlist, kn, evt);
		knote_unlock(kn);
        if (slowpath(rv < 0)) {
            dbg_puts("knote_copyout failed");
            /* XXX-FIXME: hard to handle this without losing events */
            abort();
        }

		/*
         * Certain flags cause the associated knote to be deleted
         * or disabled.
         */
        if (eventlist->flags & EV_DISPATCH) 
            knote_disable(filt, kn); //TODO: Error checking
        if (eventlist->flags & EV_ONESHOT) 
            knote_release(filt, kn); //TODO: Error checking

        /* If an empty kevent structure is returned, the event is discarded. */
        if (fastpath(eventlist->filter != 0)) {
            eventlist++;
        } else {
            dbg_puts("spurious wakeup, discarding event");
            nret--;
        }
	}

	return nret;
}

int
windows_filter_init(struct kqueue *kq, struct filter *kf)
{

	kq->kq_filt_ref[kq->kq_filt_count] = (struct filter *) kf;
    kq->kq_filt_count++;

	return (0);
}

void
windows_filter_free(struct kqueue *kq, struct filter *kf)
{

}