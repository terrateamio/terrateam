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

#define THREAD_ID (pthread_self())

/*
 * Atomic integer operations 
 */
#include <atomic.h>
#define atomic_inc      atomic_inc_32_nv
#define atomic_dec      atomic_dec_32_nv

/*
 * Event ports
 */
#include <port.h>
/* Used to set portev_events for PORT_SOURCE_USER */
#define X_PORT_SOURCE_SIGNAL  101
#define X_PORT_SOURCE_USER    102

/*
 * Hooks and prototypes
 */
#define kqueue_free_hook      solaris_kqueue_free
void    solaris_kqueue_free(struct kqueue *);

#define kqueue_init_hook      solaris_kqueue_init
int     solaris_kqueue_init(struct kqueue *);

void port_event_dequeue(port_event_t *, struct kqueue *);

/*
 * Data structures
 */
struct event_buf {
    port_event_t pe;
    TAILQ_ENTRY(event_buf) entries;
};

#endif  /* ! _KQUEUE_SOLARIS_PLATFORM_H */
