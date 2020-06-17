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
#include <sys/queue.h>
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
#if HAVE_SYS_TIMERFD_H
# include <sys/timerfd.h>
#endif

/*
 * Get the current thread ID
 */
# define _GNU_SOURCE
# include <linux/unistd.h>
# include <unistd.h>
#ifndef __ANDROID__
extern long int syscall (long int __sysno, ...);
#endif

/* Convenience macros to access the epoll descriptor for the kqueue */
#define kqueue_epoll_fd(kq)     ((kq)->epollfd)
#define filter_epoll_fd(filt)   ((filt)->kf_kqueue->epollfd)

/** Macro for populating the kn udata structure
 *
 * @param[in] _kn            to populate.
 */
#define KN_UDATA(_kn)        ((_kn)->kn_udata = (struct epoll_udata){ .ud_type = EPOLL_UDATA_KNOTE, .ud_kn = _kn })

/** Macro for populating the fds udata structure
 *
 * @param[in] _fds           to populate.
 */
#define FDS_UDATA(_fds)      ((_fds)->fds_udata = (struct epoll_udata){ .ud_type = EPOLL_UDATA_FD_STATE, .ud_fds = _fds })

/** Macro for building a temporary kn epoll_event
 *
 * @param[in] _events        One or more event flags EPOLLIN, EPOLLOUT etc...
 * @param[in] _kn            to associate with the event.  Is used to
 *                           determine the correct filter to notify
 *                           if the event fires.
 */
#define EPOLL_EV_KN(_events, _kn)    &(struct epoll_event){ .events = _events, .data = { .ptr = &(_kn)->kn_udata } }

/** Macro for building a temporary fds epoll_event
 *
 * @param[in] _events        One or more event flags EPOLLIN, EPOLLOUT etc...
 * @param[in] _fds           File descriptor state to associate with the
 *                           event. Is used during event demuxing to inform
 *                           multiple filters of read/write events on the fd.
 */
#define EPOLL_EV_FDS(_events, _fds)  &(struct epoll_event){ .events = _events, .data = { .ptr = &(_fds)->fds_udata } }

/** Macro for building a temporary epoll_event
 *
 * @param[in] _events        One or more event flags EPOLLIN, EPOLLOUT etc...
 */
#define EPOLL_EV(_events) &(struct epoll_event){ .events = _events }

/** What type of udata is in the event loop
 *
 */
enum epoll_udata_type {
    EPOLL_UDATA_KNOTE       = 0x01,     //!< Udata is a pointer to a knote.
    EPOLL_UDATA_FD_STATE    = 0x02      //!< Udata is a pointer to a fd state structure.
};

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

/** Additional members of struct filter
 *
 */
#define FILTER_PLATFORM_SPECIFIC

/** Additional members of struct knote
 *
 */
#define KNOTE_PLATFORM_SPECIFIC \
    int kn_epollfd;                       /* A copy of filter->epoll_fd */ \
    int kn_registered;                    /* Is FD registered with epoll */ \
    struct fd_state        *kn_fds;       /* File descriptor's registration state */ \
    union { \
        int kn_timerfd; \
        int kn_signalfd; \
        int kn_inotifyfd; \
        int kn_eventfd; \
    } kdata; \
    struct epoll_udata    kn_udata       /* Common struct passed to epoll */

/** Additional members of struct kqueue
 *
 */
#define KQUEUE_PLATFORM_SPECIFIC \
    int epollfd;                          /* Main epoll FD */ \
    int pipefd[2];                        /* FD for pipe that catches close */ \
    RB_HEAD(fd_st, fd_state) kq_fd_st;    /* EVFILT_READ/EVFILT_WRITE fd state */ \
    struct epoll_event kq_plist[MAX_KEVENT]; \
    size_t kq_nplist

int     linux_kqueue_init(struct kqueue *);
void    linux_kqueue_free(struct kqueue *);

int     linux_kevent_wait(struct kqueue *, int, const struct timespec *);
int     linux_kevent_copyout(struct kqueue *, int, struct kevent *, int);

int     linux_knote_copyout(struct kevent *, struct knote *);

int     linux_eventfd_init(struct eventfd *);
void    linux_eventfd_close(struct eventfd *);
int     linux_eventfd_raise(struct eventfd *);
int     linux_eventfd_lower(struct eventfd *);
int     linux_eventfd_descriptor(struct eventfd *);

/* utility functions */

int     linux_get_descriptor_type(struct knote *);
int     linux_fd_to_path(char *, size_t, int);

/* epoll-related functions */

char *  epoll_event_op_dump(int);
char *  epoll_event_flags_dump(int);
char *  epoll_event_dump(struct epoll_event *);

int     epoll_fd_state(struct fd_state **, struct knote *, bool);
int     epoll_fd_state_init(struct fd_state **, struct knote *, int);
void    epoll_fd_state_free(struct fd_state **, struct knote *, int);

bool    epoll_fd_registered(struct filter *filt, struct knote *kn);
int     epoll_update(int op, struct filter *filt, struct knote *kn, int ev, bool delete);
#endif  /* ! _KQUEUE_LINUX_PLATFORM_H */
