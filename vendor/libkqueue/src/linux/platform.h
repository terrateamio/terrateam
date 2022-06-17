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
#ifndef  _KQUEUE_LINUX_PLATFORM_H
#define  _KQUEUE_LINUX_PLATFORM_H

struct filter;

#include <sys/syscall.h>
#include <sys/epoll.h>

#include <sys/inotify.h>
#if HAVE_SYS_EVENTFD_H
# include <sys/eventfd.h>
#else
# ifdef SYS_eventfd2
#  define eventfd(a,b) syscall(SYS_eventfd2, (a), (b))
# else
#  define eventfd(a,b) syscall(SYS_eventfd, (a), (b))
# endif

  static inline int eventfd_write(int fd, uint64_t val) {
      if (write(fd, &val, sizeof(val)) < (ssize_t) sizeof(val))
          return (-1);
      else
          return (0);
  }
#endif

#include <errno.h>
#include <pthread.h>
#include <stdatomic.h>
#include <string.h>

#if HAVE_LINUX_LIMITS_H
#  include <linux/limits.h>
#else
#  include <limits.h>
#endif

#if HAVE_SYS_QUEUE_H
# include <sys/queue.h>
#else
# include "../common/queue.h"
#endif

#include <sys/resource.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/time.h>
#include <unistd.h>

/*
 * Check to see if we have SYS_pidfd_open support if we don't,
 * fall back to the POSIX EVFILT_PROC code.
 *
 * Using the build system macro makes it slightly easier to
 * toggle between POSIX/Linux implementations.
 */
#if HAVE_SYS_PIDFD_OPEN
#define KNOTE_PROC_PLATFORM_SPECIFIC  int kn_procfd;
#define FILTER_PROC_PLATFORM_SPECIFIC
#else
#include "../posix/platform_ext.h"
#define KNOTE_PROC_PLATFORM_SPECIFIC  POSIX_KNOTE_PROC_PLATFORM_SPECIFIC
#define FILTER_PROC_PLATFORM_SPECIFIC POSIX_FILTER_PROC_PLATFORM_SPECIFIC
#endif

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

/*
 * Allow us to make arbitrary syscalls
 */
# define _GNU_SOURCE
#if HAVE_LINUX_UNISTD_H
# include <linux/unistd.h>
#elif HAVE_SYSCALL_H
# include <syscall.h>
#endif
#ifndef __ANDROID__
extern long int syscall (long int __sysno, ...);
#endif

/* Workaround for Android */
#ifndef EPOLLONESHOT
# define EPOLLONESHOT (1 << 30)
#endif

/* Convenience macros to access the epoll descriptor for the kqueue */
#define kqueue_epoll_fd(kq)     ((kq)->epollfd)
#define filter_epoll_fd(filt)   ((filt)->kf_kqueue->epollfd)

/** What type of udata was passed to epoll
 *
 */
enum epoll_udata_type {
    EPOLL_UDATA_KNOTE = 1,           //!< Udata is a pointer to a knote.
    EPOLL_UDATA_FD_STATE,            //!< Udata is a pointer to a fd state structure.
    EPOLL_UDATA_EVENT_FD             //!< Udata is a pointer to an eventfd.
};

/** Macro for populating the kn_udata structure
 *
 * We set the udata for the epoll event so we can retrieve the knote associated
 * with the event when the event occurs.
 *
 * This should be called before adding a new epoll event associated with a knote.
 *
 * @param[in] _kn            to populate.
 */
#define KN_UDATA(_kn)        ((_kn)->kn_udata = (struct epoll_udata){ .ud_type = EPOLL_UDATA_KNOTE, .ud_kn = _kn })

/** Macro for populating the fds udata structure
 *
 * @param[in] _fds           to populate.
 */
#define FDS_UDATA(_fds)      ((_fds)->fds_udata = (struct epoll_udata){ .ud_type = EPOLL_UDATA_FD_STATE, .ud_fds = _fds })

/* Macro for populating an eventfd udata structure
 *
 * @param[in] _efd           to populate.
 */
#define EVENTFD_UDATA(_efd)  ((_efd)->efd_udata = (struct epoll_udata){ .ud_type = EPOLL_UDATA_EVENT_FD, .ud_efd = _efd })

/** Macro for building a temporary kn epoll_event
 *
 * @param[in] _events        One or more event flags EPOLLIN, EPOLLOUT etc...
 * @param[in] _kn            to associate with the event.  Is used to
 *                           determine the correct filter to notify
 *                           if the event fires.
 */
#define EPOLL_EV_KN(_events, _kn) &(struct epoll_event){ .events = _events, .data = { .ptr = &(_kn)->kn_udata }}

/** Macro for building a temporary fds epoll_event
 *
 * @param[in] _events        One or more event flags EPOLLIN, EPOLLOUT etc...
 * @param[in] _fds           File descriptor state to associate with the
 *                           event. Is used during event demuxing to inform
 *                           multiple filters of read/write events on the fd.
 */
#define EPOLL_EV_FDS(_events, _fds) &(struct epoll_event){ .events = _events, .data = { .ptr = &(_fds)->fds_udata }}

/** Macro for building a temporary eventfd epoll_event
 *
 * @param[in] _events        One or more event flags EPOLLIN, EPOLLOUT etc...
 * @param[in] _efd           eventfd to build event for.
 */
#define EPOLL_EV_EVENTFD(_events, _efd) &(struct epoll_event){ .events = _events, .data = { .ptr = &(_efd)->efd_udata }}

/** Macro for building a temporary epoll_event
 *
 * @param[in] _events        One or more event flags EPOLLIN, EPOLLOUT etc...
 */
#define EPOLL_EV(_events) &(struct epoll_event){ .events = _events }

/** Common structure that's provided as the epoll data.ptr
 *
 * Where an epoll event is associated with a single filter we pass in
 * a knote.  When the epoll event is associated with multiple filters
 * we pass in an fd_state struct.
 *
 * This structure is common to both, and allows us to determine the
 * type of structure associated with the epoll event.
 */
struct epoll_udata {
    union {
        struct knote        *ud_kn;     //!< Pointer back to the containing knote.
        struct fd_state     *ud_fds;    //!< Pointer back to the containing fd_state.
        struct eventfd      *ud_efd;    //!< Pointer back to the containing eventfd.
    };
    enum epoll_udata_type   ud_type;    //!< Which union member to use.
};

/** Holds cross-filter information for file descriptors
 *
 * Epoll will not allow the same file descriptor to be inserted
 * twice into the same event loop.
 *
 * To make epoll work reliably, we need to mux and demux the events
 * created by the filters interested in read/write events.
 * This structure records the read and write knotes.
 *
 * Unfortunately this has the side effect of not allowing flags like
 * EPOLLET
 *
 * We use the fact that fds_read/fds_write are nonnull to determine
 * if the FD has already been registered for a particular event when
 * we get a request to update epoll.
 */
struct fd_state {
    RB_ENTRY(fd_state)    fds_entries;    //!< Entry in the RB tree.
    int                   fds_fd;         //!< File descriptor this entry relates to.
    struct knote          *fds_read;      //!< Knote that should be informed of read events.
    struct knote          *fds_write;     //!< Knote that should be informed of write events.
    struct epoll_udata    fds_udata;      //!< Common struct passed to epoll
};

/** Additional members of struct eventfd
 *
 */
#define EVENTFD_PLATFORM_SPECIFIC \
    struct epoll_udata    efd_udata

/** Additional members of struct knote
 *
 */
#define KNOTE_PLATFORM_SPECIFIC \
    int kn_epollfd;                       /* A copy of filter->epoll_fd */ \
    int kn_registered;                    /* Is FD registered with epoll */ \
    struct fd_state        *kn_fds;       /* File descriptor's registration state */ \
    int epoll_events;                     /* Which events this file descriptor is registered for */ \
    union { \
        int kn_timerfd; \
        int kn_signalfd; \
        int kn_eventfd; \
        struct { \
            nlink_t         nlink;  \
            off_t           size;   \
            int             inotifyfd; \
        } kn_vnode; \
        KNOTE_PROC_PLATFORM_SPECIFIC; \
    }; \
    struct epoll_udata    kn_udata       /* Common struct passed to epoll */

/** Additional members of struct filter
 *
 */
#define FILTER_PLATFORM_SPECIFIC \
    FILTER_PROC_PLATFORM_SPECIFIC

/** Additional members of struct kqueue
 *
 */
#define KQUEUE_PLATFORM_SPECIFIC \
    int epollfd;                          /* Main epoll FD */ \
    int pipefd[2];                        /* FD for pipe that catches close */ \
    RB_HEAD(fd_st, fd_state) kq_fd_st;    /* EVFILT_READ/EVFILT_WRITE fd state */ \
    struct epoll_event kq_plist[MAX_KEVENT]; \
    size_t kq_nplist

int     linux_knote_copyout(struct kevent *, struct knote *);

/* utility functions */

int     linux_get_descriptor_type(struct knote *);
int     linux_fd_to_path(char *, size_t, int);

/* epoll-related functions */

char const *  epoll_op_dump(int);
char const *  epoll_event_flags_dump(const struct epoll_event *);
char const *  epoll_event_dump(const struct epoll_event *);

int     epoll_fd_state(struct fd_state **, struct knote *, bool);
int     epoll_fd_state_init(struct fd_state **, struct knote *, int);
void    epoll_fd_state_free(struct fd_state **, struct knote *, int);

bool    epoll_fd_registered(struct filter *filt, struct knote *kn);
int     epoll_update(int op, struct filter *filt, struct knote *kn, int ev, bool delete);
#endif  /* ! _KQUEUE_LINUX_PLATFORM_H */
