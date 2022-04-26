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
#include "platform.h"
#include "eventfd.h"

int
posix_kqueue_init(struct kqueue *kq)
{
    FD_ZERO(&kq->kq_fds);
    kq->kq_nfds++;
    return (0);
}

void
posix_kqueue_free(struct kqueue *kq UNUSED)
{
}

int
posix_kevent_wait(
        struct kqueue *kq,
        const struct timespec *timeout)
{
    int n, nfds;
    fd_set rfds;

    nfds = kq->kq_nfds;
    rfds = kq->kq_fds;

    dbg_puts("waiting for events");
    n = pselect(nfds, &rfds, NULL , NULL, timeout, NULL);
    if (n < 0) {
        if (errno == EINTR) {
            dbg_puts("signal caught");
            return (-1);
        }
        dbg_perror("pselect(2)");
        return (-1);
    }

    kq->kq_rfds = rfds;

    return (n);
}

int
posix_kevent_copyout(struct kqueue *kq, int nready,
        struct kevent *eventlist, int nevents)
{
    struct filter *filt;
    int i, rv, nret;

    nret = 0;
    for (i = 0; (i < NUM_ELEMENTS(kq->kq_filt) && nready > 0 && nevents > 0); i++) {
        dbg_printf("eventlist: n = %d nevents = %d", nready, nevents);
        filt = &kq->kq_filt[i];
        dbg_printf("pfd[%d] = %d", i, filt->kf_pfd);
        if (FD_ISSET(filt->kf_id, &kq->kq_rfds)) {
            dbg_printf("pending events for filter %d (%s)", filt->kf_id, filter_name(filt->kf_id));
#if 0
            rv = filt->kf_copyout(eventlist, nevents, filt, kn, evt);
            if (rv < 0) {
                dbg_puts("kevent_copyout failed");
                nret = -1;
                break;
            }
#endif
            nret += rv;
            eventlist += rv;
            nevents -= rv;
            nready--;
        }
    }

    return (nret);
}

const struct kqueue_vtable kqops = {
//    .libkqueue_fork     = posix_libkqueue_fork,
//    .libkqueue_free     = posix_libkqueue_free,
    .kqueue_init        = posix_kqueue_init,
    .kqueue_free        = posix_kqueue_free,
//    .kevent_wait        = posix_kevent_wait,
    .kevent_copyout     = posix_kevent_copyout,
//    .eventfd_register   = posix_eventfd_register,
//    .eventfd_unregister = posix_eventfd_unregister,
    .eventfd_init       = posix_eventfd_init,
    .eventfd_close      = posix_eventfd_close,
    .eventfd_raise      = posix_eventfd_raise,
    .eventfd_lower      = posix_eventfd_lower,
    .eventfd_descriptor = posix_eventfd_descriptor,
};
