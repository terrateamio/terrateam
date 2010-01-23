/*
 * Copyright (c) 2009 Mark Heily <mark@heily.com>
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

#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

#include "private.h"

extern const struct filter evfilt_read;
extern const struct filter evfilt_write;
extern const struct filter evfilt_signal;
extern const struct filter evfilt_vnode;
extern const struct filter evfilt_proc;
extern const struct filter evfilt_timer;
extern const struct filter evfilt_user;

static int
filter_register(struct kqueue *kq, short filter, const struct filter *src)
{
    struct filter *dst;
    u_int filt;
    int rv = 0;

    filt = (-1 * filter) - 1;
    if (filt >= EVFILT_SYSCOUNT) 
        return (-1);

    dst = &kq->kq_filt[filt];
    memcpy(dst, src, sizeof(*src));
    dst->kf_kqueue = kq;
    pthread_rwlock_init(&dst->kf_mtx, NULL);
    KNOTELIST_INIT(&dst->kf_watchlist);
    KNOTELIST_INIT(&dst->kf_eventlist);
    RB_INIT(&dst->kf_knote);
    LIST_INIT(&dst->kf_event);
    if (src->kf_id == 0) {
        dbg_puts("filter is not implemented");
        return (0);
    }
    if (src->kf_init == NULL) {
        dbg_puts("filter has no initializer");
        return (-1);
    }

    rv = src->kf_init(dst);
    if (rv < 0) {
        dbg_puts("filter failed to initialize");
        dst->kf_id = 0; /* FIXME: lame magic constant */ 
        return (-1);
    }

    /* Add the filter's event descriptor to the main fdset */
    if (dst->kf_pfd > 0) {
        FD_SET(dst->kf_pfd, &kq->kq_fds);
        if (dst->kf_pfd > kq->kq_nfds)  
            kq->kq_nfds = dst->kf_pfd;
        dbg_printf("fds: added %d (nfds=%d)", dst->kf_pfd, kq->kq_nfds);
    }
    dbg_printf("%s registered", filter_name(filter));

    return (0);
}

int
filter_register_all(struct kqueue *kq)
{
    int rv;

    FD_ZERO(&kq->kq_fds);
    rv = 0;
    rv += filter_register(kq, EVFILT_READ, &evfilt_read);
    rv += filter_register(kq, EVFILT_WRITE, &evfilt_write);
    rv += filter_register(kq, EVFILT_SIGNAL, &evfilt_signal);
    rv += filter_register(kq, EVFILT_VNODE, &evfilt_vnode);
    rv += filter_register(kq, EVFILT_PROC, &evfilt_proc);
    rv += filter_register(kq, EVFILT_TIMER, &evfilt_timer);
    rv += filter_register(kq, EVFILT_USER, &evfilt_user);
    kq->kq_nfds++;
    if (rv != 0) {
        filter_unregister_all(kq);
        return (-1);
    } else {
        return (0);
    }
}

void
filter_unregister_all(struct kqueue *kq)
{
    struct knote *n1, *n2;
    int i;

    for (i = 0; i < EVFILT_SYSCOUNT; i++) {
        if (kq->kq_filt[i].kf_id == 0)
            continue;

        if (kq->kq_filt[i].kf_destroy != NULL) 
            kq->kq_filt[i].kf_destroy(&kq->kq_filt[i]);

        /* Destroy all knotes associated with this filter */
        for (n1 = LIST_FIRST(&kq->kq_filt[i].kf_watchlist); n1 != NULL; n1 = n2) {
            n2 = LIST_NEXT(n1, entries);
            free(n1);
        }
        for (n1 = LIST_FIRST(&kq->kq_filt[i].kf_eventlist); n1 != NULL; n1 = n2) {
            n2 = LIST_NEXT(n1, entries);
            free(n1);
        }
    }
    memset(&kq->kq_filt[0], 0, sizeof(kq->kq_filt));
}

int 
filter_socketpair(struct filter *filt)
{
    int sockfd[2];

    if (socketpair(AF_UNIX, SOCK_STREAM, 0, sockfd) < 0)
        return (-1);

    fcntl(sockfd[0], F_SETFL, O_NONBLOCK);
    filt->kf_wfd = sockfd[0];
    filt->kf_pfd = sockfd[1];
    return (0);
} 

int
filter_lookup(struct filter **filt, struct kqueue *kq, short id)
{
    if (~id < 0 || ~id >= EVFILT_SYSCOUNT) {
        dbg_printf("invalid id: id %d ~id %d", id, (~id));
        errno = EINVAL;
        *filt = NULL;
        return (-1);
    }
    *filt = &kq->kq_filt[~id];
    if ((*filt)->kf_copyout == NULL) {
        errno = ENOSYS;
        *filt = NULL;
        return (-1);
    }

    return (0);
}

const char *
filter_name(short filt)
{
    unsigned int id;
    const char *fname[EVFILT_SYSCOUNT] = {
        "EVFILT_READ",
        "EVFILT_WRITE",
        "EVFILT_AIO", 
        "EVFILT_VNODE",
        "EVFILT_PROC",
        "EVFILT_SIGNAL", 
        "EVFILT_TIMER", 
        "EVFILT_NETDEV", 
        "EVFILT_FS",    
        "EVFILT_LIO",  
        "EVFILT_USER"
    };

    id = ~filt;
    if (id < 0 || id >= EVFILT_SYSCOUNT)
        return "EVFILT_INVALID";
    else
        return fname[id];
}

int
filter_raise(struct filter *filt)
{
    for (;;) {
        if (write(filt->kf_wfd, " ", 1) < 0) {
            if (errno == EINTR) 
                continue;

            if (errno != EAGAIN) {
                dbg_printf("write(2): %s", strerror(errno));
                /* TODO: set filter error flag */
                return (-1);
            }
        }
        break;
    }

    return (0);
}

int
filter_lower(struct filter *filt)
{
    char buf[1024];
    ssize_t n;

    for (;;) {
        n = read(filt->kf_pfd, &buf, sizeof(buf));
        if (n < 0) {
            if (errno == EINTR) 
                continue;
            if (errno == EAGAIN) 
                break;

            dbg_printf("read(2): %s", strerror(errno));
            return (-1);
        }
        break;
    }

    return (0);
}
