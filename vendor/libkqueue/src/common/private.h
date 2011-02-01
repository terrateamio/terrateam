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

#include <errno.h>
#include <stdio.h>
#include <string.h>
#include "tree.h"

/* Maximum events returnable in a single kevent() call */
#define MAX_KEVENT  512

struct kqueue;
struct kevent;
struct knote;
struct eventfd;
struct evfilt_data;

#if defined(_WIN32)
# include "../windows/platform.h"
# include "../common/queue.h"
#elif defined(__linux__)
# include "../posix/platform.h"
# include "../linux/platform.h"
#elif defined(__sun)
# include "../posix/platform.h"
# include "../solaris/platform.h"
#else
# error Unknown platform
#endif

#include <assert.h>

extern int KQUEUE_DEBUG;

#ifndef NDEBUG
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

    /* The event_buf structure is only needed by Solaris */
    struct DEADWOOD_event_buf {
        int unused;
    };


/* 
 * Flags used by knote->flags
 */
#define KNFL_PASSIVE_SOCKET  (0x01)  /* Socket is in listen(2) mode */

struct eventfd {
    int ef_id;
#if defined(EVENTFD_PLATFORM_SPECIFIC)
    EVENTFD_PLATFORM_SPECIFIC;
#endif
};

/* TODO: Make this a variable length structure and allow
   each filter to add custom fields at the end.
 */
struct knote {
    struct kevent     kev;
    int               flags;       
    union {
        /* OLD */
        int           pfd;       /* Used by timerfd */
        int           events;    /* Used by socket */
        struct {
            nlink_t   nlink;  /* Used by vnode */
            off_t     size;   /* Used by vnode */
        } vnode;
        timer_t       timerid;  
        pthread_t     tid;          /* Used by posix/timer.c */
		void          *handle;      /* Used by win32 filters */
    } data;
#if defined(KNOTE_PLATFORM_SPECIFIC)
    KNOTE_PLATFORM_SPECIFIC;
#endif
    TAILQ_ENTRY(knote) event_ent;    /* Used by filter->kf_event */
    RB_ENTRY(knote)   kntree_ent;   /* Used by filter->kntree */
};

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
    int     (*kf_copyout)(struct kevent *, const struct kqueue *, struct filter *, struct knote *, void *);

    /* knote operations */

    int     (*kn_create)(struct filter *, struct knote *);
    int     (*kn_modify)(struct filter *, struct knote *, 
                            const struct kevent *);
    int     (*kn_delete)(struct filter *, struct knote *);
    int     (*kn_enable)(struct filter *, struct knote *);
    int     (*kn_disable)(struct filter *, struct knote *);

    struct eventfd kf_efd;             /* Used by user.c */

#if DEADWOOD
    //MOVE TO POSIX?
    int       kf_pfd;                   /* fd to poll(2) for readiness */
    int       kf_wfd;                   /* fd to write when an event occurs */
#endif

    struct evfilt_data *kf_data;	    /* filter-specific data */
    RB_HEAD(knt, knote) kf_knote;
    struct kqueue      *kf_kqueue;
#if defined(FILTER_PLATFORM_SPECIFIC)
    FILTER_PLATFORM_SPECIFIC;
#endif
};

/* Use this to declare a filter that is not implemented */
#define EVFILT_NOTIMPL { 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL }

struct kqueue {
    int             kq_id;
    struct filter   kq_filt[EVFILT_SYSCOUNT];
    fd_set          kq_fds, kq_rfds; 
    int             kq_nfds;
    pthread_mutex_t kq_mtx;
    volatile uint32_t  kq_ref;
#if defined(KQUEUE_PLATFORM_SPECIFIC)
    KQUEUE_PLATFORM_SPECIFIC;
#endif
    RB_ENTRY(kqueue) entries;
};

struct kqueue_vtable {
    int  (*kqueue_init)(struct kqueue *);
    void (*kqueue_free)(struct kqueue *);
	int  (*kevent_wait)(struct kqueue *, int, const struct timespec *);
    int  (*kevent_copyout)(struct kqueue *, int, struct kevent *, int);
    int  (*filter_init)(struct kqueue *, struct filter *);
    void (*filter_free)(struct kqueue *, struct filter *);
    int  (*eventfd_init)(struct eventfd *);
    void (*eventfd_close)(struct eventfd *);
    int  (*eventfd_raise)(struct eventfd *);
    int  (*eventfd_lower)(struct eventfd *);
    int  (*eventfd_descriptor)(struct eventfd *);
};
extern const struct kqueue_vtable kqops;

struct knote *  knote_lookup(struct filter *, short);
struct knote *  knote_lookup_data(struct filter *filt, intptr_t);
struct knote *  knote_new(void);
void        knote_free(struct filter *, struct knote *);
void        knote_free_all(struct filter *);
void        knote_insert(struct filter *, struct knote *);
int         knote_get_socket_type(struct knote *);

/* TODO: these deal with the eventlist, should use a different prefix */
//DEADWOOD:void        knote_enqueue(struct filter *, struct knote *);
//DEADWOOD:struct knote *  knote_dequeue(struct filter *);
//DEADWOOD:int         knote_events_pending(struct filter *);
int         knote_disable(struct filter *, struct knote *);

int         filter_lookup(struct filter **, struct kqueue *, short);
int      	filter_register_all(struct kqueue *);
void     	filter_unregister_all(struct kqueue *);
const char *filter_name(short);

int         kevent_wait(struct kqueue *, const struct timespec *);
int         kevent_copyout(struct kqueue *, int, struct kevent *, int);
void 		kevent_free(struct kqueue *);
const char *kevent_dump(const struct kevent *);

struct kqueue * kqueue_get(int);
void        kqueue_put(struct kqueue *);
int         kqueue_validate(struct kqueue *);
#define     kqueue_lock(kq)     pthread_mutex_lock(&(kq)->kq_mtx)
#define     kqueue_unlock(kq)   pthread_mutex_unlock(&(kq)->kq_mtx)

int CONSTRUCTOR _libkqueue_init(void);

#endif  /* ! _KQUEUE_PRIVATE_H */
