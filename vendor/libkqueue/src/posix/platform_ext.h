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

#ifndef  _KQUEUE_POSIX_PLATFORM_EXT_H
#define  _KQUEUE_POSIX_PLATFORM_EXT_H

/** Additional members of 'struct eventfd'
 *
 * These should be included in the platform's EVENTFD_PLATFORM_SPECIFIC
 * macro definition if using the POSIX eventfd functions.
 */
#define POSIX_EVENTFD_PLATFORM_SPECIFIC \
    int             ef_wfd

/** Additional members of 'struct knote'
 *
 * These should be included in the platform's KNOTE_PLATFORM_SPECIFIC
 * macro definition if using the POSIX proc filter.
 */
#define POSIX_KNOTE_PROC_PLATFORM_SPECIFIC \
    struct { \
        LIST_ENTRY(knote) kn_proc_waiter; \
        int kn_proc_status; \
    }

/** Additional members of 'struct filter'
 *
 * These should be included in the platform's FILTER_PLATFORM_SPECIFIC
 * macro definition if using the POSIX proc filter.
 */
#define POSIX_FILTER_PROC_PLATFORM_SPECIFIC \
    struct { \
        struct eventfd  kf_proc_eventfd; \
        pthread_t kf_proc_thread_id; \
    }

/** Additional members of 'struct filter'
 *
 * These should be included in the platform's FILTER_PLATFORM_SPECIFIC
 * macro definition if using all the POSIX filters.
 */
#define POSIX_FILTER_PLATFORM_SPECIFIC \
    int             kf_pfd; /* fd to poll(2) for readiness */ \
    int             kf_wfd; \
    POSIX_FILTER_PROC_PLATFORM_SPECIFIC

/** Additional members of 'struct kqueue'
 *
 * These should be included in the platform's KQUEUE_PLATFORM_SPECIFIC
 * macro definition.
 */
#define POSIX_KQUEUE_PLATFORM_SPECIFIC \
    fd_set          kq_fds, kq_rfds; \
    int             kq_nfds

/** Additional members of 'struct knote'
 *
 */
#define POSIX_KNOTE_PLATFORM_SPECIFIC \
    POSIX_KNOTE_PROC_PLATFORM_SPECIFIC; \
    struct sleepreq *kn_sleepreq

#endif  /* ! _KQUEUE_POSIX_PLATFORM_EXT_H */
