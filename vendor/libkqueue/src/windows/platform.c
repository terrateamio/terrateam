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
            /* XXX-FIXME: initialize kqtree mutex */
            if (WSAStartup(MAKEWORD(2,2), NULL) != 0)
                return (FALSE);
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
