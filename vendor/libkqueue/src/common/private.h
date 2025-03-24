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
#include <stdarg.h>
#include <sys/types.h>
/* Required by glibc for MAP_ANON */
#define __USE_MISC 1
#include <stdlib.h>

#include "config.h"
#include "sys/event.h"
#include "tree.h"
#include "version.h"

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
#elif defined(__EMSCRIPTEN__)
# include "../posix/platform.h"
#else
# error Unknown platform
#endif

/** Additional macro to check if an item is in a doubly linked list
 *
 */
#define LIST_INSERTED(elm, field) (((elm)->field.le_next) || ((elm)->field.le_prev))

/** Variant of LIST_REMOVE which sets next/prev fields to NULL so that LIST_INSERTED works
 *
 */
#define LIST_REMOVE_ZERO(elm, field) do { \
    LIST_REMOVE(elm, field); \
    (elm)->field.le_next = NULL; \
    (elm)->field.le_prev = NULL; \
} while(0)

/** On Linux LIST_FOREACH_SAFE isn't provided
 *
 */
#ifndef LIST_FOREACH_SAFE
#define	LIST_FOREACH_SAFE(var, head, field, tvar)			\
	for ((var) = LIST_FIRST((head));				\
	    (var) && ((tvar) = LIST_NEXT((var), field), 1);		\
	    (var) = (tvar))
#endif

/** Convenience macros
 *
 */
#define NUM_ELEMENTS(_t) (sizeof((_t)) / sizeof(*(_t)))

#define XSTRINGIFY(x) #x
#define STRINGIFY(x) XSTRINGIFY(x)

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
#define UNUSED
#define UNUSED_NDEBUG
#endif

/*
 * Check for LLVM TSAN
 */
#if defined(__has_feature)
#  if __has_feature(thread_sanitizer)
#    define TSAN_IGNORE  __attribute__((no_sanitize("thread")))
#    define HAVE_TSAN_IGNORE
#  endif
#endif

/*
 * Check for GCC TSAN
 */
#ifdef __SANITIZE_THREAD__
#  define TSAN_IGNORE  __attribute__((no_sanitize("thread")))
#  define HAVE_TSAN_IGNORE
#endif

#ifndef HAVE_TSAN_IGNORE
#  define TSAN_IGNORE
#endif

/*
 * Bit twiddling
 */
#define COPY_FLAGS_BIT(_dst, _src, _flag) (_dst).flags = ((_dst).flags & ~(_flag)) | ((_src).flags & (_flag))
#define COPY_FFLAGS_BIT(_dst, _src, _flag) (_dst).fflags = ((_dst).fflags & ~(_flag)) | ((_src).fflags & (_flag))

#include "debug.h"

/** An eventfd provides a mechanism to signal the eventing system that an event has occurred
 *
 * This is usually that a filter has pending events that it wants handled during the
 * next call to copyout.
 */
struct eventfd {
    int ef_id;                                   //!< The file descriptor associated
                                                 ///< with this eventfd.
    struct filter *ef_filt;                      //!< The filter associated with this eventfd.

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

/** A knote representing an event we need to notify a caller of `kevent() ` about
 *
 * Knotes are usually associated with a single filter, and hold information about
 * an event that the caller (of `kevent()`) is interested in receiving.
 *
 * Knotes often hold a lot of platform specific data such as file descriptors and
 * handles for different eventing/notification systems.
 *
 * Knotes are reference counted, meaning multiple filters (may in theory) hold a
 * reference to them.  Deleting a knote from one filter may not free it entirely.
 */
struct knote {
    struct kevent          kev;                //!< kevent used to create this knote.
                                               ///< Contains flags/fflags/data/udata etc.

    unsigned int           kn_flags;           //!< Internal flags used to record additional
                                               ///< information about the knote.  i.e. whether
                                               ///< it is enabled and what type of
                                               ///< socket/file/device it refers to.
                                               ///< See the KNFL_* macros for more details.

    struct kqueue          *kn_kq;             //!< kqueue this knote is associated with.
    atomic_uint            kn_ref;             //!< Reference counter for this knote.

    RB_ENTRY(knote)        kn_index;           //!< Entry in tree holding all knotes associated
                                               ///< with a given filter.

    LIST_ENTRY(knote)      kn_ready;           //!< Entry in a linked list of knotes which are
                                               ///< ready for copyout.  This isn't used for all
                                               ///< filters.

#if defined(KNOTE_PLATFORM_SPECIFIC)
    KNOTE_PLATFORM_SPECIFIC;
#endif

};

/** Mark a knote as enabled
 */
#define KNOTE_ENABLE(_kn) do {    \
                              (_kn)->kev.flags &= ~EV_DISABLE;\
} while (0/*CONSTCOND*/)

/** Mark a knote as disabled
 */
#define KNOTE_DISABLE(_kn) do {     \
                              (_kn)->kev.flags |=  EV_DISABLE; \
} while (0/*CONSTCOND*/)

/** Check if a knote is enabled
 */
#define KNOTE_ENABLED(_kn)    (!((_kn)->kev.flags & EV_DISABLE))

/** Check if a knote is disabled
 */
#define KNOTE_DISABLED(_kn)   ((_kn)->kev.flags & EV_DISABLE)

/** Clear the EOF flags
 */
#define KNOTE_EOF_CLEAR(_kn) do {    \
                              (_kn)->kev.flags &= ~EV_EOF;\
} while (0/*CONSTCOND*/)

/** Mark a knote as EOF
 */
#define KNOTE_EOF_SET(_kn) do {     \
                              (_kn)->kev.flags |=  EV_EOF; \
} while (0/*CONSTCOND*/)

/** Check if a knote is EOF
 */
#define KNOTE_IS_EOF(_kn)     ((_kn)->kev.flags & EV_EOF)

/** Check if a knote is EOF
 */
#define KNOTE_NOT_EOF(_kn)    (!((_kn)->kev.flags & EV_EOF))

/** A filter (discreet notification channel) within a kqueue
 *
 * Filters are discreet event notification facilities within a kqueue.
 * Filters do not usually interact with each other, and maintain separate states.
 *
 * Filters handle notifications from different event sources.
 * The EVFILT_READ filter, for example, provides notifications when an FD is
 * readable, and the EVFILT_SIGNAL filter provides notifications when a particular
 * signal is received by the process/thread.
 *
 * Many of the fields in this struct are callbacks for functions which operate
 * on the filer or its knotes.
 *
 * Callbacks either change the state of the filter itself, or
 * create/modify/delete knotes associated with the filter.
 * The knotes describe a filter-specific event the application is interested in
 * receiving.
 *
 */
struct filter {
    short                  kf_id;              //!< EVFILT_* facility this filter provides.

    /** Called once on startup
     *
     */
    void                   (*libkqueue_init)(void);

#ifndef _WIN32
    /** Called on fork (for the child)
     *
     * Always called with kq_mtx held to ensure global resources
     * are in a a consistent state for cleanup.
     */
    void                   (*libkqueue_fork)(void);
#endif

    /** Called at exit
     *
     */
    void                   (*libkqueue_free)(void);

    /** Perform initialisation for this filter
     *
     * This is called once per filer per kqueue as the kqueue is initialised.
     *
     * @param[in] filt    to initialise.
     * @return
     *    - 0 on success.
     *    - -1 on failure.
     */
    int                    (*kf_init)(struct filter *filt);

    /** Perform de-initialisation for this filter
     *
     * This is called once per filter per kqueue as the kqueue is freed.
     *
     * This function should free/release any handles or other resources
     * held by the filter.
     */
    void                   (*kf_destroy)(struct filter *filt);

    /** Copy an event from the eventing system to a kevent structure
     *
     * @param[in] el     array of `struct kevent` to populate.  Most filters
     *                   will insert a single event, but some may insert multiple.
     * @param[in] nevents The maximum number of events to copy to el.
     * @param[in] filt   we're copying out events from.
     * @param[in] kn     the event was triggered on.
     * @param[in] ev     event system specific structure representing the event,
     *                   i.e. for Linux this would be a `struct epoll_event *`.
     * @return
     *    - >=0 the number of events copied to el.
     *    - -1 on failure setting errno.
     */
    int                    (*kf_copyout)(struct kevent *el, int nevents, struct filter *filt, struct knote *kn, void *ev);

    /** Complete filter-specific initialisation of a knote
     *
     * @note This function should not allocate a `struct knote`, zero out the
     *       `struct knote`, or insert the knote into the kf_index.
     *       This is done in common code.
     *
     * This function should allocate any handles or other resources required for
     * the knote, and fill in any filter specific data in the knote's structure.
     *
     * @note Currently all knotes are created "enabled" by the various filters.
     *       This is arguably a bug, and should be fixed in a future release.
     *
     * @param[in] filt     the knote is associated with.
     * @param[in] kn       to initialise.
     * @return
     *    - 1 to create an entry in the eventlist using the contents
     *      of kn->kev.
     *    - 0 on success.
     *    - -1 on failure setting errno.
     */
    int                    (*kn_create)(struct filter *filt, struct knote *kn);

    /** Modify a knote
     *
     * This is called when an entry in a changelist is found which has the same
     * identifier as a knote associated with this filter.
     *
     * This function should examine kev and kn->kev for differences and make
     * appropriate changes to the knote's event registrations and internal
     * state.
     *
     * This function should also copy the contents of kev to kn->kev if all
     * changes were successful.
     *
     * Changes must be atomic, that is, if this function experiences an error
     * making the requested modifications to the knote, the knote should revert
     * to the state it was in (and with the same registations) as when this
     * function was called.
     *
     * @param[in] filt     the knote is associated with.
     * @param[in] kn       to modify.
     * @param[in] kev      the entry in the changelist which triggered the
     *                     modification.
     *
     * @return
     *    - 1 to create an entry in the eventlist using the contents
     *      of kn->kev.
     *    - 0 on success.
     *    - -1 on failure setting errno.
     */
    int                    (*kn_modify)(struct filter *filt, struct knote *kn, const struct kevent *kev);

    /** Delete a knote
     *
     * This is called either when a kqueue is being freed or when a relevant
     * EV_DELETE flag is found in the changelist.
     *
     * @note This function should not free the `struct knote` of remove the
     *       knote from the kf_index.  This is done in common code.
     *
     * This function should deregister any file descriptors associated with
     * this knote from the platform's eventing system.
     *
     * This function should close all file descriptors and free any other
     * resources used by this knote.
     *
     * Changes must be atomic, that is, if this function experiences an error
     * deleting the knote, the knote should revert to the state it was in
     * (and with the same registations) as when this function was called.
     *
     * @param[in] filt     the knote is associated with.
     * @param[in] kn       to delete.
     * @return
     *    - 1 to create an entry in the eventlist using the contents
     *      of kn->kev.
     *    - 0 on success.
     *    - -1 on failure setting errno.
     */
    int                    (*kn_delete)(struct filter *filt, struct knote *kn);

    /** Enable a knote
     *
     * This is called when a knote is enabled (after first being disabled).
     *
     * The idea behind having the enable/disable flags for knotes is that it
     * allows the caller of `kevent()` to temporarily pause (and later re-enable)
     * delivery of notifications without allocating, freeing or releasing any
     * resources.
     *
     * Enabling a knote should re-add any previously removed file descriptors
     * from the platform's eventing system.
     *
     * Changes must be atomic, that is, if this function experiences an
     * error deleting the knote, the knote should revert to the state it
     * was in (and with the same registations) as when this function was
     * called.
     *
     * @param[in] filt     the knote is associated with.
     * @param[in] kn       to enable.
     * @return
     *    - 1 to create an entry in the eventlist using the contents
     *      of kn->kev.
     *    - 0 on success.
     *    - -1 on failure setting errno.
     */
    int                    (*kn_enable)(struct filter *filt, struct knote *kn);

    /** Disable a knote
     *
     * This is called when a knote is disabled (after first being created or
     * enabled).
     *
     * Disabling a knote should remove any previously added file descriptors
     * from the platform's eventing system.
     *
     * @note This function should not remove the knote from the filter's
     *       ready list (if used), as this is done in common code.
     *
     * Changes must be atomic, that is, if this function experiences an
     * error disabling the knote, the knote should revert to the state it
     * was in (and with the same registations) as when this function was
     * called.
     *
     * @param[in] filt     the knote is associated with.
     * @param[in] kn       to disable.
     * @return
     *    - 1 to create an entry in the eventlist using the contents
     *      of kn->kev.
     *    - 0 on success.
     *    - -1 on failure setting errno.
     */
    int                    (*kn_disable)(struct filter *filt, struct knote *kn);

    struct evfilt_data     *kf_data;           //!< Filter-specific data.

    RB_HEAD(knote_index, knote) kf_index;      //!< Tree of knotes. This is for easy lookup
                                               ///< and removal of knotes.  All knotes are
                                               ///< directly owned by a filter.

    struct eventfd         kf_efd;             //!< An eventfd associated with the filter.
                                               ///< This is used in conjunction with the
                                               ///< kf_ready list.  When the eventfd is
                                               ///< "raised", and the platform's eventing
                                               ///< is blocked (waiting for events), the
                                               ///< current epoll/select/etc... call returns
                                               ///< and we process the knotes in the kf_ready
                                               ///< list.
                                               ///< This is not used by all filters.

    LIST_HEAD(knote_ready, knote) kf_ready;    //!< knotes which are ready for copyout.
                                               ///< This is used for filters which don't
                                               ///< raise events using the platform's
                                               ///< eventing system, and instead signal
                                               ///< with eventfds.
                                               ///< This is not used by all filters.

    struct kqueue          *kf_kqueue;         //!< kqueue this filter is associated with.

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
    int                    kq_id;              //!< File descriptor used to identify this kqueue.

    LIST_ENTRY(kqueue)     kq_entry;           //!< Entry in the global list of active kqueues.

    struct filter          kq_filt[EVFILT_SYSCOUNT];    //!< Filters supported by the kqueue.  Each
                                               ///< kqueue maintains one filter state structure
                                               ///< per filter type.
    tracing_mutex_t        kq_mtx;

#if defined(KQUEUE_PLATFORM_SPECIFIC)
    KQUEUE_PLATFORM_SPECIFIC;
#endif
};

/** Platform specific support functions
 *
 */
struct kqueue_vtable {
    /** Called once on startup
     *
     */
    void   (*libkqueue_init)(void);

#ifndef _WIN32
    /** Called on fork (for the child)
     *
     * Always called with kq_mtx held to ensure global resources
     * are in a a consistent state for cleanup.
     */
    void   (*libkqueue_fork)(void);
#endif

    /** Called at exit
     *
     */
    void   (*libkqueue_free)(void);

    /** Called once for every kqueue created
     *
     */
    int    (*kqueue_init)(struct kqueue *kq);

    /** Called when a kqueue is destroyed
     *
     */
    void   (*kqueue_free)(struct kqueue *kq);

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
    int    (*kevent_wait)(struct kqueue *kq, int numevents, const struct timespec *ts);

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
    int    (*kevent_copyout)(struct kqueue *kq, int nready, struct kevent *el, int);

    /** Perform platform specific initialisation for filters
     *
     * Called once per kqueue per filter.
     */
    int    (*filter_init)(struct kqueue *kq, struct filter *filt);

    /** Perform platform specific de-initialisation for filters
     *
     * Called once per kqueue per filter.
     */
    void   (*filter_free)(struct kqueue *kq, struct filter *filt);

    /** Register an eventfd with the eventing system associated with this kqueue
     *
     * @param[in] kq            To register the event fd for.
     * @param[in] efd           to register.
     * @return
     *      - 0 on success.
     *      - -1 on failure.
     */
    int    (*eventfd_register)(struct kqueue *kq, struct eventfd *efd);

    /** Remove an eventfd from the eventing system associated with this kqueue
     *
     * @param[in] kq            To remove the event fd from.
     * @param[in] efd           Eventfd to remove.
     */
    void   (*eventfd_unregister)(struct kqueue *kq, struct eventfd *efd);

    /** Initialise a new eventfd
     *
     * @param[in] efd           structure to initialise.
     * @param[in] filt          Filter to associate this eventfd with.
     * @return
     *      - 0 on success.
     *      - -1 on failure.
     */
    int    (*eventfd_init)(struct eventfd *efd, struct filter *filt);

    /** Close an eventfd
     *
     * @param[in] efd           to close.
     * @return
     *      - 0 on success.
     *      - -1 on failure.
     */
    void   (*eventfd_close)(struct eventfd *efd);

    /** "raise" an eventfd, i.e. signal it as pending
     *
     * @param[in] efd           to raise.
     * @return
     *      - 0 on success.
     *      - -1 on failure.
     */
    int    (*eventfd_raise)(struct eventfd *efd);

    /** "lower" an eventfd, consume the pending signal
     *
     * @param[in] efd           to lower.
     * @return
     *      - 0 on success.
     *      - -1 on failure.
     */
    int    (*eventfd_lower)(struct eventfd *efd);

    /** Return the file descriptor associated with an eventfd
     *
     * @param[in] efd           to return the file descriptor for.
     * @return The file descriptor.
     */
    int    (*eventfd_descriptor)(struct eventfd *efd);
};
LIST_HEAD(kqueue_head, kqueue);

extern bool libkqueue_thread_safe;
extern bool libkqueue_fork_cleanup;
extern const struct kqueue_vtable kqops;
extern tracing_mutex_t kq_mtx;
extern struct kqueue_head kq_list;
extern unsigned int kq_cnt;

/*
 * kqueue internal API
 */
#define kqueue_mutex_assert(kq, state) tracing_mutex_assert(&(kq)->kq_mtx, state)
#define kqueue_lock(kq)                tracing_mutex_lock(&(kq)->kq_mtx)
#define kqueue_unlock(kq)              tracing_mutex_unlock(&(kq)->kq_mtx)

/*
 * knote internal API
 */
struct knote    *knote_lookup(struct filter *, uintptr_t);
int             knote_delete_all(struct filter *filt);
int             knote_mark_disabled_all(struct filter *filt);
struct knote    *knote_new(void);

#define knote_retain(kn) atomic_inc(&kn->kn_ref)
void            knote_release(struct knote *);
void            knote_insert(struct filter *, struct knote *);
int             knote_delete(struct filter *, struct knote *);
int             knote_disable(struct filter *, struct knote *);
int             knote_enable(struct filter *, struct knote *);
int             knote_modify(struct filter *, struct knote *);

/** Common code for respecting EV_DISPATCH and EV_ONESHOT
 *
 * This should be called by every filter for every knote
 * processed.
 *
 * Unfortunately we can't do this internally as `struct kevent`
 * does not contain references to the knotes which created
 * the kevents.
 *
 * - EV_DISPATCH disable the knote after an event occurs.
 * - EV_ONESHOT delete the knote after an event occurs.
 */
static inline int knote_copyout_flag_actions(struct filter *filt, struct knote *kn)
{
    int rv = 0;

    /*
     * Certain flags cause the associated knote to be deleted
     * or disabled.
     */
    if (kn->kev.flags & EV_DISPATCH)
        rv = knote_disable(filt, kn);

    if (kn->kev.flags & EV_ONESHOT)
        rv = knote_delete(filt, kn);

    return rv;
}

#define knote_get_filter(knt) &((knt)->kn_kq->kq_filt[~(knt)->kev.filter])

void            filter_init_all(void);
#ifndef _WIN32
void            filter_fork_all(void);
#endif
void            filter_free_all(void);

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
void            kqueue_knote_mark_disabled_all(struct kqueue *kq);
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
