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

static VOID CALLBACK
evfilt_read_callback(void *param, BOOLEAN fired)
{
    struct kqueue *kq;
    struct knote *kn;

    assert(param);

    if (fired) {
        dbg_puts("called, but event was not triggered(?)");
        return;
    }
    
	assert(param);
	kn = (struct knote*)param;
    // FIXME: check if knote is pending destroyed
	kq = kn->kn_kq;
	assert(kq);

    if (!PostQueuedCompletionStatus(kq->kq_iocp, 1, (ULONG_PTR) 0, (LPOVERLAPPED) param)) {
        dbg_lasterror("PostQueuedCompletionStatus()");
        return;
        /* FIXME: need more extreme action */
    }

    /* DEADWOOD 
    kn = (struct knote *) param;
    evt_signal(kn->kn_kq->kq_loop, EVT_WAKEUP, kn);
    */
}

#if FIXME
static intptr_t
get_eof_offset(int fd)
{
    off_t curpos;
    struct stat sb;

    curpos = lseek(fd, 0, SEEK_CUR);
    if (curpos == (off_t) -1) {
        dbg_perror("lseek(2)");
        curpos = 0;
    }
    if (fstat(fd, &sb) < 0) {
        dbg_perror("fstat(2)");
        sb.st_size = 1;
    }

    dbg_printf("curpos=%zu size=%zu\n", curpos, sb.st_size);
    return (sb.st_size - curpos); //FIXME: can overflow
}
#endif

int
evfilt_read_copyout(struct kevent *dst, struct knote *src, void *ptr)
{
#if FIXME
    struct event_buf * const ev = (struct event_buf *) ptr;

    /* FIXME: for regular files, return the offset from current position to end of file */
    //if (src->flags & KNFL_REGULAR_FILE) { ... }

    epoll_event_dump(ev);
    memcpy(dst, &src->kev, sizeof(*dst));
#if defined(HAVE_EPOLLRDHUP)
    if (ev->events & EPOLLRDHUP || ev->events & EPOLLHUP)
        dst->flags |= EV_EOF;
#else
    if (ev->events & EPOLLHUP)
        dst->flags |= EV_EOF;
#endif
    if (ev->events & EPOLLERR)
        dst->fflags = 1; /* FIXME: Return the actual socket error */
          
    if (src->flags & KNFL_PASSIVE_SOCKET) {
        /* On return, data contains the length of the 
           socket backlog. This is not available under Linux.
         */
        dst->data = 1;
    } else {
        /* On return, data contains the number of bytes of protocol
           data available to read.
         */
        if (ioctl(dst->ident, SIOCINQ, &dst->data) < 0) {
            /* race condition with socket close, so ignore this error */
            dbg_puts("ioctl(2) of socket failed");
            dst->data = 0;
        }
    }
#endif

    return (0);
}

int
evfilt_read_knote_create(struct filter *filt, struct knote *kn)
{
    HANDLE evt;
    int rv;

    /* Create an auto-reset event object */
    evt = CreateEvent(NULL, FALSE, FALSE, NULL);
    if (evt == NULL) {
        dbg_lasterror("CreateEvent()");
        return (-1);
    }

    rv = WSAEventSelect(
                (SOCKET) kn->kev.ident, 
                evt, 
                FD_READ | FD_ACCEPT | FD_CLOSE);
    if (rv != 0) {
        dbg_wsalasterror("WSAEventSelect()");
        CloseHandle(evt);
        return (-1);
    }
    
    /* TODO: handle regular files in addition to sockets */

    /* TODO: handle in copyout
    if (kn->kev.flags & EV_ONESHOT || kn->kev.flags & EV_DISPATCH)
        kn->data.events |= EPOLLONESHOT;
    if (kn->kev.flags & EV_CLEAR)
        kn->data.events |= EPOLLET;
    */

	if (RegisterWaitForSingleObject(&kn->kn_event_whandle, evt, 
                evfilt_read_callback, kn, INFINITE, 0) == 0) {
        dbg_puts("RegisterWaitForSingleObject failed");
        CloseHandle(evt);
        return (-1);
    }

    kn->data.handle = evt;

    return (0);
}

int
evfilt_read_knote_modify(struct filter *filt, struct knote *kn, 
        const struct kevent *kev)
{
    return (-1); /* STUB */
}

int
evfilt_read_knote_delete(struct filter *filt, struct knote *kn)
{
    if (kn->kev.flags & EV_DISABLE)
        return (0);

    if (kn->data.handle == NULL || kn->kn_event_whandle == NULL)
        return (0);

	if(!UnregisterWaitEx(kn->kn_event_whandle, INVALID_HANDLE_VALUE)) {
		dbg_lasterror("UnregisterWait()");
		return (-1);
	}
	if (!WSACloseEvent(kn->data.handle)) {
		dbg_wsalasterror("WSACloseEvent()");
		return (-1);
	}

    kn->data.handle = NULL;
    return (0);
}

int
evfilt_read_knote_enable(struct filter *filt, struct knote *kn)
{
    return evfilt_read_knote_create(filt, kn);
}

int
evfilt_read_knote_disable(struct filter *filt, struct knote *kn)
{
    return evfilt_read_knote_delete(filt, kn);
}

const struct filter evfilt_read = {
    EVFILT_READ,
    NULL,
    NULL,
    evfilt_read_copyout,
    evfilt_read_knote_create,
    evfilt_read_knote_modify,
    evfilt_read_knote_delete,
    evfilt_read_knote_enable,
    evfilt_read_knote_disable,         
};
