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

#ifndef  _KQUEUE_POSIX_PLATFORM_H
#define  _KQUEUE_POSIX_PLATFORM_H

#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <poll.h>
#include <pthread.h>
#include <signal.h>
#include <stdint.h>
#include <string.h>
#include <stdatomic.h>
#include <sys/resource.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <unistd.h>
#include "../common/queue.h"
#include "platform_ext.h"

#define EVENTFD_PLATFORM_SPECIFIC	POSIX_EVENTFD_PLATFORM_SPECIFIC
#define KNOTE_PROC_PLATFORM_SPECIFIC	POSIX_KNOTE_PROC_PLATFORM_SPECIFIC
#define PROC_PLATFORM_SPECIFIC		POSIX_PROC_PLATFORM_SPECIFIC
#define FILTER_PLATFORM_SPECIFIC	POSIX_FILTER_PLATFORM_SPECIFIC
#define KQUEUE_PLATFORM_SPECIFIC	POSIX_KQUEUE_PLATFORM_SPECIFIC
#define KNOTE_PLATFORM_SPECIFIC		POSIX_KNOTE_PLATFORM_SPECIFIC

/*
 * C11 atomic operations
 */
#define atomic_inc(p)                 (atomic_fetch_add((p), 1) + 1)
#define atomic_dec(p)                 (atomic_fetch_sub((p), 1) - 1)

/* We use compound literals here to stop the 'expected' values from being overwritten */
#define atomic_cas(p, oval, nval)     atomic_compare_exchange_strong(p, &(__typeof__(oval)){ oval }, nval)
#define atomic_ptr_cas(p, oval, nval) atomic_compare_exchange_strong(p, (&(uintptr_t){ (uintptr_t)oval }), (uintptr_t)nval)
#define atomic_ptr_swap(p, nval)      atomic_exchange(p, (uintptr_t)nval)
#define atomic_ptr_load(p)            atomic_load(p)

void    posix_kqueue_free(struct kqueue *);
int     posix_kqueue_init(struct kqueue *);

int     posix_kevent_wait(struct kqueue *, const struct timespec *);
int     posix_kevent_copyout(struct kqueue *, int, struct kevent *, int);

#endif  /* ! _KQUEUE_POSIX_PLATFORM_H */
