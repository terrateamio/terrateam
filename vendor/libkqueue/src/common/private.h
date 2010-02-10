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

#ifndef  _KQUEUE_PRIVATE_H
#define  _KQUEUE_PRIVATE_H

#if defined (__SVR4) && defined (__sun)
#define SOLARIS
#include <port.h>
#endif

#include <errno.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <sys/select.h>
#include "sys/event.h"

#include "tree.h"

/* GCC atomic builtins. 
 * See: http://gcc.gnu.org/onlinedocs/gcc-4.1.0/gcc/Atomic-Builtins.html 
 */
#define atomic_inc(p)   __sync_add_and_fetch((p), 1)
#define atomic_dec(p)   __sync_sub_and_fetch((p), 1)

/* Maximum events returnable in a single kevent() call */
#define MAX_KEVENT  512

#ifdef KQUEUE_DEBUG
# define dbg_puts(str)           fprintf(stderr, "%s(): %s\n", __func__,str)
# define dbg_printf(fmt,...)     fprintf(stderr, "%s(): "fmt"\n", __func__,__VA_ARGS__)
# define dbg_perror(str)         fprintf(stderr, "%s(): %s: %s\n", __func__,str, strerror(errno))
#else
# define dbg_puts(str)           ;
# define dbg_printf(fmt,...)     ;
# define dbg_perror(str)         ;
#endif 

struct kqueue;
struct kevent;
struct evfilt_data;

/* TODO: Make this a variable length structure and allow
   each filter to add custom fields at the end.
 */
struct knote {
    struct kevent     kev;
    union {
        int           kn_pfd;       /* Used by timerfd */
        int           kn_events;    /* Used by socket */
        struct {
            nlink_t   kn_st_nlink;  /* Used by vnode */
            off_t     kn_st_size;   /* Used by vnode */
        };
    };
    TAILQ_ENTRY(knote) event_ent;    /* Used by filter->kf_event */
    RB_ENTRY(knote)   kntree_ent;   /* Used by filter->kntree */
};
LIST_HEAD(knotelist, knote);

#define KNOTE_ENABLE(ent)           do {                            \
            (ent)->kev.flags &= ~EV_DISABLE;                        \
} while (0/*CONSTCOND*/)

#define KNOTE_DISABLE(ent)          do {                            \
            (ent)->kev.flags |=  EV_DISABLE;                        \
} while (0/*CONSTCOND*/)

struct filter {
    int       kf_id;

    /* filter operations */

    int     (*kf_init)(struct filter *);
    void    (*kf_destroy)(struct filter *);
    int     (*kf_copyout)(struct filter *, struct kevent *, int);

    /* knote operations */

    int     (*kn_create)(struct filter *, struct knote *);
    int     (*kn_modify)(struct filter *, struct knote *, 
                            const struct kevent *);
    int     (*kn_delete)(struct filter *, struct knote *);
    int     (*kn_enable)(struct filter *, struct knote *);
    int     (*kn_disable)(struct filter *, struct knote *);

    struct eventfd *kf_efd;             /* Used by user.c */
    int       kf_pfd;                   /* fd to poll(2) for readiness */
    int       kf_wfd;                   /* fd to write when an event occurs */
    u_int     kf_timeres;               /* timer resolution, in miliseconds */
    sigset_t  kf_sigmask;
    struct evfilt_data *kf_data;	/* filter-specific data */
    RB_HEAD(knt, knote) kf_knote;
    TAILQ_HEAD(, knote)  kf_event;       /* events that have occurred */
    struct kqueue *kf_kqueue;
};

struct kqueue {
    int             kq_sockfd[2];
    struct filter   kq_filt[EVFILT_SYSCOUNT];
    fd_set          kq_fds, kq_rfds; 
    int             kq_nfds;
    pthread_mutex_t kq_mtx;
#ifdef SOLARIS
    int             kq_port;
#endif
    volatile unsigned int    kq_ref;
    RB_ENTRY(kqueue) entries;
};

struct knote *  knote_lookup(struct filter *, short);
struct knote *  knote_lookup_data(struct filter *filt, intptr_t);
struct knote *  knote_new(void);
void        knote_free(struct filter *, struct knote *);
void        knote_free_all(struct filter *);
void        knote_insert(struct filter *, struct knote *);

/* TODO: these deal with the eventlist, should use a different prefix */
void        knote_enqueue(struct filter *, struct knote *);
struct knote *  knote_dequeue(struct filter *);
int         knote_events_pending(struct filter *);

struct eventfd * eventfd_create(void);
void        eventfd_free(struct eventfd *);
int         eventfd_raise(struct eventfd *);
int         eventfd_lower(struct eventfd *);
int         eventfd_reader(struct eventfd *);
int         eventfd_writer(struct eventfd *);

int         filter_lookup(struct filter **, struct kqueue *, short);
int         filter_socketpair(struct filter *);
int      	filter_register_all(struct kqueue *);
void     	filter_unregister_all(struct kqueue *);
const char *filter_name(short);
int         filter_lower(struct filter *);
int         filter_raise(struct filter *);

int 		kevent_init(struct kqueue *);
int         kevent_wait(struct kqueue *, const struct timespec *);
int         kevent_copyout(struct kqueue *, int, struct kevent *, int);
void 		kevent_free(struct kqueue *);
const char *kevent_dump(const struct kevent *);

struct kqueue * kqueue_get(int);
void        kqueue_put(struct kqueue *);
#define     kqueue_lock(kq)     pthread_mutex_lock(&(kq)->kq_mtx)
#define     kqueue_unlock(kq)   pthread_mutex_unlock(&(kq)->kq_mtx)
int         kqueue_validate(struct kqueue *);

#endif  /* ! _KQUEUE_PRIVATE_H */
