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

#include <pthread.h>
#include <stdio.h>
#include <sys/select.h>
#include "sys/event.h"

/* Maximum events returnable in a single kevent() call */
#define MAX_KEVENT  512

#ifdef KQUEUE_DEBUG
# define dbg_puts(str)           fprintf(stderr, "%s\n", str)
# define dbg_printf(fmt,...)     fprintf(stderr, fmt"\n", __VA_ARGS__)
# define dbg_perror(str)         fprintf(stderr, "%s: %s\n", str, strerror(errno))
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
    int               kn_pfd;       /* Used by timerfd */
    nlink_t           kn_st_nlink;  /* Used by vnode */
    off_t             kn_st_size;   /* Used by vnode */
    LIST_ENTRY(knote) entries;
};
LIST_HEAD(knotelist, knote);

/* TODO: This should be a red-black tree or a heap */
#define KNOTELIST_INIT(knl)         LIST_INIT((knl))
#define KNOTELIST_FOREACH(ent,knl)  LIST_FOREACH((ent),(knl), entries)
#define KNOTELIST_EMPTY(knl)        LIST_EMPTY((knl))
#define KNOTE_INSERT(knl, ent)      LIST_INSERT_HEAD((knl), (ent), entries)
#define KNOTE_EMPTY(ent)            ((ent)->kev.filter == 0)

#define KNOTE_ENABLE(ent)           do {                            \
            (ent)->kev.flags &= ~EV_DISABLE;                        \
} while (0/*CONSTCOND*/)

#define KNOTE_DISABLE(ent)          do {                            \
            (ent)->kev.flags |=  EV_DISABLE;                        \
} while (0/*CONSTCOND*/)

struct filter {
    int       kf_id;
    int     (*kf_init)(struct filter *);
    void    (*kf_destroy)(struct filter *);
    int     (*kf_copyin)(struct filter *, 
                         struct knote *, 
                         const struct kevent *);
    int     (*kf_copyout)(struct filter *, struct kevent *, int);
    int       kf_pfd;                   /* fd to poll(2) for readiness */
    int       kf_wfd;                   /* fd to write when an event occurs */
    u_int     kf_timeres;               /* timer resolution, in miliseconds */
    sigset_t  kf_sigmask;
    struct evfilt_data *kf_data;	/* filter-specific data */
    struct knotelist knl; 
    struct kqueue *kf_kqueue;
};

struct kqueue {
    int             kq_sockfd[2];
    pthread_t       kq_close_tid;
    struct filter   kq_filt[EVFILT_SYSCOUNT];
    fd_set          kq_fds; 
    int             kq_nfds;
    pthread_mutex_t kq_mtx;
    LIST_ENTRY(kqueue) entries;
};

struct knote *  knote_lookup(struct filter *, short);
struct knote *  knote_lookup_data(struct filter *filt, intptr_t);
struct knote *  knote_new(struct filter *);
void 		    knote_free(struct knote *);

struct filter *  filter_lookup(struct kqueue *, short);
int         filter_socketpair(struct filter *);
int      	filter_register_all(struct kqueue *);
void     	filter_unregister_all(struct kqueue *);
const char *filter_name(short);

int 		kevent_init(struct kqueue *);
const char * kevent_dump(struct kevent *);
int 		kevent_wait(struct kqueue *kq,
                        struct kevent *kevent, 
                        int nevents,
                        const struct timespec *timeout);
void 		kevent_free(struct kqueue *);

struct kqueue * kqueue_lookup(int kq);
void            kqueue_lock(struct kqueue *kq);
void            kqueue_unlock(struct kqueue *kq);

#endif  /* ! _KQUEUE_PRIVATE_H */
