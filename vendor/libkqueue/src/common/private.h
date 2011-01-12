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

struct kqueue;
struct kevent;
struct evfilt_data;

#include <errno.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <sys/select.h>
#include "../../include/sys/event.h"

#include "tree.h"

/* GCC atomic builtins. 
 * See: http://gcc.gnu.org/onlinedocs/gcc-4.1.0/gcc/Atomic-Builtins.html 
 */
#ifdef __sun
# include <atomic.h>
# define atomic_inc      atomic_inc_32_nv
# define atomic_dec      atomic_dec_32_nv
#else
# define atomic_inc(p)   __sync_add_and_fetch((p), 1)
# define atomic_dec(p)   __sync_sub_and_fetch((p), 1)
#endif

/* Maximum events returnable in a single kevent() call */
#define MAX_KEVENT  512


#ifndef NDEBUG

extern int KQUEUE_DEBUG;

#ifdef __linux__
# define _GNU_SOURCE
# include <linux/unistd.h>
# include <sys/syscall.h>
# include <unistd.h>
extern long int syscall (long int __sysno, ...);
# define THREAD_ID ((pid_t) syscall(__NR_gettid))
#else
# define THREAD_ID (pthread_self())
#endif

#define dbg_puts(str)           do {                                \
    if (KQUEUE_DEBUG)                                               \
      fprintf(stderr, "KQ [%d]: %s(): %s\n", THREAD_ID, __func__,str);              \
} while (0)

#define dbg_printf(fmt,...)     do {                                \
    if (KQUEUE_DEBUG)                                               \
      fprintf(stderr, "KQ [%d]: %s(): "fmt"\n", THREAD_ID, __func__,__VA_ARGS__);   \
} while (0)

#define dbg_perror(str)         do {                                \
    if (KQUEUE_DEBUG)                                               \
      fprintf(stderr, "KQ: [%d] %s(): %s: %s (errno=%d)\n",              \
              THREAD_ID, __func__, str, strerror(errno), errno);               \
} while (0)

# define reset_errno()          do { errno = 0; } while (0)

#else /* NDEBUG */
# define dbg_puts(str)           ;
# define dbg_printf(fmt,...)     ;
# define dbg_perror(str)         ;
# define reset_errno()           ;
#endif 

#if defined (__SVR4) && defined (__sun)
# define SOLARIS
# include <port.h>
  /* Used to set portev_events for PORT_SOURCE_USER */
# define X_PORT_SOURCE_SIGNAL  101
# define X_PORT_SOURCE_USER    102

# define kqueue_free_hook      solaris_kqueue_free
void    solaris_kqueue_free(struct kqueue *);

# define kqueue_init_hook      solaris_kqueue_init
int     solaris_kqueue_init(struct kqueue *);

void port_event_dequeue(port_event_t *, struct kqueue *);

struct event_buf {
    port_event_t pe;
    TAILQ_ENTRY(event_buf) entries;
};

#else 
    /* The event_buf structure is only needed by Solaris */
    struct event_buf {
        int unused;
    };
#endif


/* 
 * Flags used by knote->flags
 */
#define KNFL_PASSIVE_SOCKET  (0x01)  /* Socket is in listen(2) mode */

/* TODO: Make this a variable length structure and allow
   each filter to add custom fields at the end.
 */
struct knote {
    struct kevent     kev;
    int               flags;       
    union {
        int           pfd;       /* Used by timerfd */
        int           events;    /* Used by socket */
        struct {
            nlink_t   nlink;  /* Used by vnode */
            off_t     size;   /* Used by vnode */
        } vnode;
        timer_t       timerid;  
        pthread_t     tid;          /* Used by posix/timer.c */
    } data;
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
    short     kf_id;

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
    sigset_t            kf_sigmask;
    struct evfilt_data *kf_data;	    /* filter-specific data */
    RB_HEAD(knt, knote) kf_knote;
    TAILQ_HEAD(, knote) kf_event;       /* events that have occurred */
    struct kqueue      *kf_kqueue;
};

/* Use this to declare a filter that is not implemented */
#define EVFILT_NOTIMPL { 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL }

struct kqueue {
    int             kq_sockfd[2];
    struct filter   kq_filt[EVFILT_SYSCOUNT];
    fd_set          kq_fds, kq_rfds; 
    int             kq_nfds;
    pthread_mutex_t kq_mtx;
#ifdef __sun__
    int             kq_port;            /* see: port_create(2) */
    TAILQ_HEAD(event_buf_listhead,event_buf) kq_events;
#endif
    volatile uint32_t        kq_ref;
    RB_ENTRY(kqueue) entries;
};

struct knote *  knote_lookup(struct filter *, short);
struct knote *  knote_lookup_data(struct filter *filt, intptr_t);
struct knote *  knote_new(void);
void        knote_free(struct filter *, struct knote *);
void        knote_free_all(struct filter *);
void        knote_insert(struct filter *, struct knote *);
int         knote_get_socket_type(struct knote *);

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
