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
const struct filter evfilt_user = EVFILT_NOTIMPL;

const struct kqueue_vtable kqops = {
    windows_kqueue_init,
    windows_kqueue_free,
	windows_kevent_wait,
	windows_kevent_copyout,
	windows_filter_init,
	windows_filter_free,
};

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
            break;

        case DLL_PROCESS_DETACH:
#if XXX
            WSACleanup();
#endif
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

	if(filter_register_all(kq) < 0) {
		CloseHandle(kq->kq_handle);
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
    rv = WaitForMultipleObjectsEx(kq->kq_filt_count, kq->kq_filt_handle, FALSE, timeout_ms, TRUE);
	switch (rv) {
	case WAIT_TIMEOUT:
		dbg_puts("no events within the given timeout");
		retval = 0;
		break;

	case WAIT_FAILED:
		dbg_lasterror("WaitForMultipleEvents()");
		retval = -1;

	default:
		kq->kq_filt_signalled = rv;
		retval = 1;
	}
	
    return (retval);
}

int
windows_kevent_copyout(struct kqueue *kq, int nready,
        struct kevent *eventlist, int nevents)
{
    struct filter *filt;
	struct knote* kn;
    int rv;

	/* KLUDGE: We are abusing the WAIT_FAILED constant to mean
	that there are no filters with pending events.
	*/
	if (kq->kq_filt_signalled == WAIT_FAILED)
		return (0);
	filt = kq->kq_filt_ref[kq->kq_filt_signalled];
	kn = knote_lookup(filt, eventlist->ident);
	if(kn == NULL) {
		dbg_puts("knote_lookup failed");
		return (-1);
	}
	kq->kq_filt_signalled = WAIT_FAILED;
    rv = filt->kf_copyout(eventlist, kn, filt);
    if (rv < 0) {
        dbg_puts("kevent_copyout failed");
        return (-1);
    }
	return (1);
}

int
windows_filter_init(struct kqueue *kq, struct filter *kf)
{
	HANDLE h;

	h = CreateEvent(NULL, FALSE, FALSE, NULL);
    if (h == NULL) {
        dbg_perror("CreateEvent()");
        return (-1);
    }
	kf->kf_event_handle = h;

	/* Add the handle to the kqueue filter table */
	kq->kq_filt_handle[kq->kq_filt_count] = h;
	kq->kq_filt_ref[kq->kq_filt_count] = (struct filter *) kf;
    kq->kq_filt_count++;

	return (0);
}

void
windows_filter_free(struct kqueue *kq, struct filter *kf)
{
	CloseHandle(kf->kf_event_handle);
	/* FIXME: Remove the handle from the kqueue filter table */
}