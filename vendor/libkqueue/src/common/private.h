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

/** Frequently used headers that should be standard on all platforms
 *
 */
#include <fcntl.h>
#include <stdbool.h>
#include <stdio.h>
#include <sys/types.h>
/* Required by glibc for MAP_ANON */
#define __USE_MISC 1
#include <stdlib.h>

#include "config.h"
#include "tree.h"
#include "sys/event.h"

/* Maximum events returnable in a single kevent() call */
#define MAX_KEVENT  512

struct kqueue;
struct kevent;
struct knote;
struct map;
struct eventfd;
struct evfilt_data;

#if defined(_WIN32)
# include "../windows/platform.h"

# if !defined(NDEBUG) && !defined(__GNUC__)
#  include <crtdbg.h>
# endif
#elif defined(__linux__)
# include "../linux/platform.h"
#elif defined(__sun)
# include "../solaris/platform.h"
#else
# error Unknown platform
#endif

/** Additional macro to check if an item is in a doubly linked list
 *
 */
#define LIST_INSERTED(elm, field) (((elm)->field.le_next) || ((elm)->field.le_prev))

/** Convenience macros
 *
 */
#define NUM_ELEMENTS(_t) (sizeof((_t)) / sizeof(*(_t)))

#if defined(__clang__) || defined(__GNUC__)
/*
 * Branch prediction macros
 */
#define likely(x)       __builtin_expect((x), 1)
#define unlikely(x)     __builtin_expect((x), 0)

/*
 * Compiler attributes
 */
#define VISIBLE         __attribute__((visibility("default")))
#define HIDDEN          __attribute__((visibility("hidden")))
#define UNUSED          __attribute__((unused))
#ifndef NDEBUG
#define UNUSED_NDEBUG   __attribute__((unused))
#else
#define UNUSED_NDEBUG
#endif
#else
#define likely(x)       (x)
#define unlikely(x)     (x)
#define VISIBLE
#define HIDDEN
#define UNUSED_NDEBUG
#endif

#include "debug.h"

/* Workaround for Android */
#ifndef EPOLLONESHOT
# define EPOLLONESHOT (1 << 30)
#endif

struct eventfd {
    int ef_id;
#if defined(EVENTFD_PLATFORM_SPECIFIC)
    EVENTFD_PLATFORM_SPECIFIC;
#endif
};

/*
 * Flags used by knote->kn_flags
 */
#define KNFL_FILE                (1U << 0U)
#define KNFL_PIPE                (1U << 1U)
#define KNFL_BLOCKDEV            (1U << 2U)
#define KNFL_CHARDEV             (1U << 3U)
#define KNFL_SOCKET_PASSIVE      (1U << 4U)
#define KNFL_SOCKET_STREAM       (1U << 5U)
#define KNFL_SOCKET_DGRAM        (1U << 6U)
#define KNFL_SOCKET_RDM          (1U << 7U)
#define KNFL_SOCKET_SEQPACKET    (1U << 8U)
#define KNFL_SOCKET_RAW          (1U << 9U)
#define KNFL_KNOTE_DELETED       (1U << 31U)
#define KNFL_SOCKET              (KNFL_SOCKET_STREAM |\
                                  KNFL_SOCKET_DGRAM |\
                                  KNFL_SOCKET_RDM |\
                                  KNFL_SOCKET_SEQPACKET |\
                                  KNFL_SOCKET_RAW)

struct knote {
    struct kevent     kev;           //!< kevent used to create this knote.
                                     ///< Contains flags/fflags/data/udata etc.

    unsigned int      kn_flags;      //!< Internal flags used to record additional
                                     ///< information about the knote.  i.e. whether
                                     ///< it is enabled and what type of
                                     ///< socket/file/device it refers to.
                                     ///< See the KNFL_* macros for more details.
    union {
        /* OLD */
        int             pfd;         //!< Used by timerfd.
        int             events;      //!< Used by socket.
        struct {
            nlink_t         nlink;       //!< Used by vnode.
            off_t           size;        //!< Used by vnode.
        } vnode;
        timer_t         timerid;
        struct sleepreq *sleepreq;  //!< Used by posix/timer.c.
        void            *handle;    //!< Used by win32 filters.
    } data;

    struct kqueue       *kn_kq;     //!< kqueue this knote is associated with.
    atomic_uint         kn_ref;
#if defined(KNOTE_PLATFORM_SPECIFIC)
    KNOTE_PLATFORM_SPECIFIC;
#endif
    RB_ENTRY(knote)   kn_entries;
};

/** Mark a knote as enabled
 */
#define KNOTE_ENABLE(_kn)           do {                            \
            (_kn)->kev.flags &= ~EV_DISABLE;                       \
} while (0/*CONSTCOND*/)

/** Mark a knote as disabled
 */
#define KNOTE_DISABLE(_kn)          do {                            \
            (_kn)->kev.flags |=  EV_DISABLE;                       \
} while (0/*CONSTCOND*/)

#define KNOTE_ENABLED(_kn)    (!((_kn)->kev.flags & EV_DISABLE))
#define KNOTE_DISABLED(_kn)   ((_kn)->kev.flags & EV_DISABLE)

/** A filter within a kqueue notification channel
 *
 * Filters are discreet event notification facilities within a kqueue.
 * Filters do not usually interact with each other, and maintain separate states.
 *
 * Filters handle notifications from different event sources.
 * The EVFILT_READ filter, for example, provides notifications when an FD is
 * readable, and EVFILT_SIGNAL filter provides notifications when a particular
 * signal is received by the process/thread.
 *
 * Many of the fields in this struct are callbacks for functions which operate
 * on the filer.
 *
 * Callbacks either change the state of the filter itself, or create new
 * knotes associated with the filter.  The knotes describe a filter-specific
 * event the application is interested in receiving.
 *
 */
struct filter {
    short           kf_id;                        //!< EVFILT_* facility this filter provides.

    /* filter operations */
    int            (*kf_init)(struct filter *);
    void           (*kf_destroy)(struct filter *);

    /** Copy an event from the eventing system to a kevent structure
     *
     * @param[in] el     array of `struct kevent` to populate.  Most filters
     *                   will insert a single event, but some may insert multiple.
     * @param[in] nevents The maximum number of events to copy to el.
     * @param[in] kn     the event was triggered on.
     * @param[in] ev     event system specific structure representing the event,
     *                   i.e. for Linux this would be a `struct epoll_event *`.
     * @return
     *    - >=0 the number of events copied to el.
     *    - -1 on failure.
     */
    int            (*kf_copyout)(struct kevent *el, int nevents, struct knote *kn, void *ev);

    /* knote operations */
    int            (*kn_create)(struct filter *, struct knote *);
    int            (*kn_modify)(struct filter *, struct knote *, const struct kevent *);
    int            (*kn_delete)(struct filter *, struct knote *);
    int            (*kn_enable)(struct filter *, struct knote *);
    int            (*kn_disable)(struct filter *, struct knote *);

    struct eventfd kf_efd;                       //!< Used by user.c

    //MOVE TO POSIX?
    int           kf_pfd;                        //!< fd to poll(2) for readiness
    int           kf_wfd;                        //!< fd to write when an event occurs
    //----?

    struct evfilt_data *kf_data;                 //!< filter-specific data */
    RB_HEAD(knt, knote) kf_knote;
    pthread_rwlock_t    kf_knote_mtx;
    struct kqueue      *kf_kqueue;
#if defined(FILTER_PLATFORM_SPECIFIC)
    FILTER_PLATFORM_SPECIFIC;
#endif
};

/* Use this to declare a filter that is not implemented */
#define EVFILT_NOTIMPL { .kf_id = 0 }

/** Structure representing a notification channel
 *
 * Structure used to track the events that an application is interesting
 * in receiving notifications for.
 */
struct kqueue {
    int             kq_id;                       //!< File descriptor used to identify this kqueue.
    struct filter   kq_filt[EVFILT_SYSCOUNT];    //!< Filters supported by the kqueue.  Each
                                                 ///< kqueue maintains one filter state structure
                                                 ///< per filter type.
    tracing_mutex_t kq_mtx;
    volatile uint32_t kq_ref;

#if defined(KQUEUE_PLATFORM_SPECIFIC)
    KQUEUE_PLATFORM_SPECIFIC;
#endif
};

/** Platform specific support functions
 *
 */
struct kqueue_vtable {
    /** Called once for every kqueue created
     *
     */
    int  (*kqueue_init)(struct kqueue *kq);

    /** Called when a kqueue is destroyed
     *
     */
    void (*kqueue_free)(struct kqueue *kq);

    /** Wait on this platform's eventing system to produce events
     *
     * ...or return if there are no events within the timeout period.
     *
     * @param[in] kq            The queue to wait on.
     * @param[in] numevents     The number of events to wait for.
     * @param[in] ts            How long to wait before returning.
     *                          May be NULL if no timeout is required.
     * @return The number of events that ocurred.
     */
    int  (*kevent_wait)(struct kqueue *kq, int numevents, const struct timespec *ts);

    /** Translate events produced by the eventing system to kevents
     *
     * @param[in] kq            to retrieve events from.
     * @param[in] nready        The number of events kevent_wait indicated were ready.
     * @param[out] el           The structure to copy the events into.
     * @param[in] nevents       The maximum number of events we're allowed to produce.
     *                          This indicates how much free space is available in the
     *                          kevent structure.
     * @return The number of events we copied.
     */
    int  (*kevent_copyout)(struct kqueue *kq, int nready, struct kevent *el, int);

    /** Perform platform specific initialisation for filters
     *
     * Called once per kqueue per filter.
     */
    int  (*filter_init)(struct kqueue *kq, struct filter *filt);

    /** Perform platform specific de-initialisation for filters
     *
     * Called once per kqueue per filter.
     */
    void (*filter_free)(struct kqueue *kq, struct filter *filt);

    /** Initialise a new eventfd
     *
     * @param[in] efd           structure to initialise.
     * @return
     *      - 0 on success.
     *      - -1 on failure.
     */
    int  (*eventfd_init)(struct eventfd *efd);

    /** Close an eventfd
     *
     * @param[in] efd           to close.
     * @return
     *      - 0 on success.
     *      - -1 on failure.
     */
    void (*eventfd_close)(struct eventfd *efd);

    /** "raise" an eventfd, i.e. signal it as pending
     *
     * @param[in] efd           to raise.
     * @return
     *      - 0 on success.
     *      - -1 on failure.
     */
    int  (*eventfd_raise)(struct eventfd *efd);

    /** "lower" an eventfd, consume the pending signal
     *
     * @param[in] efd           to lower.
     * @return
     *      - 0 on success.
     *      - -1 on failure.
     */
    int  (*eventfd_lower)(struct eventfd *efd);

    /** Return the file descriptor associated with an eventfd
     *
     * @param[in] efd           to return the file descriptor for.
     * @return The file descriptor.
     */
    int  (*eventfd_descriptor)(struct eventfd *efd);
};
extern const struct kqueue_vtable kqops;

/*
 * kqueue internal API
 */
#define kqueue_lock(kq)     tracing_mutex_lock(&(kq)->kq_mtx)
#define kqueue_unlock(kq)   tracing_mutex_unlock(&(kq)->kq_mtx)

/*
 * knote internal API
 */
int             knote_delete_all(struct filter *filt);
struct knote    *knote_lookup(struct filter *, uintptr_t);
struct knote    *knote_new(void);

#define knote_retain(kn) atomic_inc(&kn->kn_ref)

void            knote_release(struct knote *);
void            knote_insert(struct filter *, struct knote *);
int             knote_delete(struct filter *, struct knote *);
int             knote_init(void);
int             knote_disable(struct filter *, struct knote *);
int             knote_enable(struct filter *, struct knote *);
int             knote_modify(struct filter *, struct knote *);

#define knote_get_filter(knt) &((knt)->kn_kq->kq_filt[(knt)->kev.filter])

int             filter_lookup(struct filter **, struct kqueue *, short);
int             filter_register_all(struct kqueue *);
void            filter_unregister_all(struct kqueue *);
const char      *filter_name(short);

unsigned int    get_fd_limit(void);
unsigned int    get_fd_used(void);

int             kevent_wait(struct kqueue *, const struct timespec *);
int             kevent_copyout(struct kqueue *, int, struct kevent *, int);
void            kevent_free(struct kqueue *);
const char      *kevent_dump(const struct kevent *);
struct kqueue   *kqueue_lookup(int);
void            kqueue_free(struct kqueue *);
void            kqueue_free_by_id(int id);
int             kqueue_validate(struct kqueue *);

struct map      *map_new(size_t);
int             map_insert(struct map *, int, void *);
int             map_remove(struct map *, int, void *);
int             map_replace(struct map *, int, void *, void *);
void            *map_lookup(struct map *, int);
void            *map_delete(struct map *, int);
void            map_free(struct map *);

#endif  /* ! _KQUEUE_PRIVATE_H */
