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

#ifndef  _KQUEUE_SOLARIS_PLATFORM_H
#define  _KQUEUE_SOLARIS_PLATFORM_H

#include <atomic.h>
#include <errno.h>
#include <pthread.h>
#include <string.h>
#include <sys/queue.h>
#include <sys/resource.h>
#include <sys/time.h>

#include "../posix/eventfd.h"

#define atomic_uintptr_t                  uintptr_t
#define atomic_uint                       unsigned int
#define atomic_inc                        atomic_inc_32_nv
#define atomic_dec                        atomic_dec_32_nv
#define atomic_cas(p, oval, nval)         (atomic_cas(p, oval, nval) == oval)
#define atomic_ptr_cas(p, oval, nval)     (atomic_cas_ptr(p, oval, nval) == oval)
#define atomic_ptr_swap(p, nval)          (atomic_swap_ptr(p, nval)
#define atomic_ptr_load(p)                (*p)

/*
 * Event ports
 */
#include <port.h>
/* Used to set portev_events for PORT_SOURCE_USER */
#define X_PORT_SOURCE_SIGNAL  101
#define X_PORT_SOURCE_USER    102

/* Convenience macros to access the event port descriptor for the kqueue */
#define kqueue_epoll_fd(kq)     ((kq)->kq_id)
#define filter_epoll_fd(filt)   ((filt)->kf_kqueue->kq_id)

void    solaris_kqueue_free(struct kqueue *);
int     solaris_kqueue_init(struct kqueue *);

/*
 * Data structures
 */
struct event_buf {
    port_event_t pe;
    TAILQ_ENTRY(event_buf) entries;
};

#define KNOTE_PLATFORM_SPECIFIC \
    timer_t         kn_timerid

#define FILTER_PLATFORM_SPECIFIC \
    int             kf_pfd

#endif  /* ! _KQUEUE_SOLARIS_PLATFORM_H */
