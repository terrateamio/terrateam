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

/* Required by glibc for MAP_ANON */
#define __USE_MISC 1

#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <poll.h>
#include <pthread.h>
#include <signal.h>
#include <stdint.h>
#include <string.h>
#include <sys/queue.h>
#include <sys/resource.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <unistd.h>

/*
 * Additional members of 'struct eventfd'
 */
#define EVENTFD_PLATFORM_SPECIFIC \
    int ef_wfd

#define KQUEUE_PLATFORM_SPECIFIC \
    fd_set          kq_fds, kq_rfds; \
    int             kq_nfds

void    posix_kqueue_free(struct kqueue *);
int     posix_kqueue_init(struct kqueue *);

int     posix_kevent_wait(struct kqueue *, const struct timespec *);
int     posix_kevent_copyout(struct kqueue *, int, struct kevent *, int);

#endif  /* ! _KQUEUE_POSIX_PLATFORM_H */
