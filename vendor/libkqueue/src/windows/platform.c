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

struct event_queue {
    HANDLE notifier;
    HANDLE events[MAXIMUM_WAIT_OBJECTS];
    size_t nevents;
};

BOOL WINAPI DllMain(
        HINSTANCE self,
        DWORD reason,
        LPVOID unused)
{
    switch (reason) { 
        case DLL_PROCESS_ATTACH:
            /* XXX-FIXME: initialize kqtree mutex */
            if (WSAStartup(MAKEWORD(2,2), NULL) != 0)
                return (FALSE);
            /* TODO: bettererror handling */
            break;

        case DLL_PROCESS_DETACH:
            WSACleanup();
            break;
    }

    return (TRUE);
}

__declspec(dllexport) EVENT_QUEUE
CreateEventQueue(void)
{
    EVENT_QUEUE *evq;

    evq = calloc(1, sizeof(*evq));
    if (evq == NULL)
        return (NULL);
    evq->notifier = CreateEvent(NULL, FALSE, FALSE, NULL);
    if (evq->notifier == NULL) {
        free(evq);
        return (NULL);
    }

    return (evq);
}

__declspec(dllexport) int
WaitForEventQueueObject(EVENT_QUEUE kq, const struct kevent *changelist, int nchanges,
	    struct kevent *eventlist, int nevents,
	    const struct timespec *timeout)
{
    return (0);
}

__declspec(dllexport) void
DestroyEventQueue(EVENT_QUEUE kq)
{
    CloseHandle(kq->notifier);
    free(kq);
}
