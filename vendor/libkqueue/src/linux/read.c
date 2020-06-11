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
#include <linux/sockios.h>
#include <pthread.h>
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/ioctl.h>
#include <sys/queue.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <string.h>
#include <unistd.h>

#include "private.h"

/*
 * Return the offset from the current position to end of file.
 */
static intptr_t
get_eof_offset(int fd)
{
    off_t curpos;
    struct stat sb;

    curpos = lseek(fd, 0, SEEK_CUR);
    if (curpos == (off_t) -1) {
        dbg_perror("lseek(2)");
        curpos = 0;
    }
    if (fstat(fd, &sb) < 0) {
        dbg_perror("fstat(2)");
        sb.st_size = 1;
    }

    dbg_printf("curpos=%zu size=%zu", (size_t)curpos, (size_t)sb.st_size);
    return (sb.st_size - curpos); //FIXME: can overflow
}

int
evfilt_read_copyout(struct kevent *dst, struct knote *src, void *ptr)
{
    int ret;
    int serr;
    socklen_t slen = sizeof(serr);
    struct epoll_event * const ev = (struct epoll_event *) ptr;

    /* Special case: for regular files, return the offset from current position to end of file */
    if (src->kn_flags & KNFL_FILE) {
        memcpy(dst, &src->kev, sizeof(*dst));
        dst->data = get_eof_offset(src->kev.ident);

        if (dst->data == 0) {
            dst->filter = 0;    /* Will cause the kevent to be discarded */
            if (epoll_ctl(src->kn_epollfd, EPOLL_CTL_DEL, src->kdata.kn_eventfd, NULL) < 0) {
                dbg_perror("epoll_ctl(2)");
                return (-1);
            }
            src->kn_registered = 0;

#if FIXME
            /* XXX-FIXME Switch to using kn_inotifyfd to monitor for IN_ATTRIB events
                         that may signify the file size has changed.

                         This code is not tested.
             */
            int inofd;
            char path[PATH_MAX];

            inofd = inotify_init();
            if (inofd < 0) {
                dbg_perror("inotify_init(2)");
                (void) close(inofd);
                return (-1);
            }
            src->kdata.kn_inotifyfd = inofd;
            if (linux_fd_to_path(path, sizeof(path), src->kev.ident) < 0)
                return (-1);
            if (inotify_add_watch(inofd, path, IN_ATTRIB) < 0) {
                dbg_perror("inotify_add_watch");
                return (-1);
            }
            if (epoll_ctl(src->kn_epollfd, EPOLL_CTL_ADD, src->kdata.kn_inotifyfd, NULL) < 0) {
                dbg_perror("epoll_ctl(2)");
                return (-1);
            }
            /* FIXME: race here, should we check the EOF status again ? */
#endif
        }

        return (0);
    }

    dbg_printf("epoll: %s", epoll_event_dump(ev));
    memcpy(dst, &src->kev, sizeof(*dst));
#if defined(HAVE_EPOLLRDHUP)
    if (ev->events & EPOLLRDHUP || ev->events & EPOLLHUP)
        dst->flags |= EV_EOF;
#else
    if (ev->events & EPOLLHUP)
        dst->flags |= EV_EOF;
#endif
    if (ev->events & EPOLLERR) {
        if (src->kn_flags & KNFL_SOCKET) {
            ret = getsockopt(src->kev.ident, SOL_SOCKET, SO_ERROR, &serr, &slen);
            dst->fflags = ((ret < 0) ? errno : serr);
        } else { dst->fflags = EIO; }
    }

    if (src->kn_flags & KNFL_SOCKET_PASSIVE) {
        /* On return, data contains the length of the
           socket backlog. This is not available under Linux.
         */
        dst->data = 1;
    } else {
        /* On return, data contains the number of bytes of protocol
           data available to read.
         */
        int i;
        if (ioctl(dst->ident, SIOCINQ, &i) < 0) {
            /* race condition with socket close, so ignore this error */
            dbg_puts("ioctl(2) of socket failed");
            dst->data = 0;
        } else {
            dst->data = i;
            if (dst->data == 0 && src->kn_flags & KNFL_SOCKET_STREAM)
                dst->flags |= EV_EOF;
        }
    }

    return (0);
}

int
evfilt_read_knote_create(struct filter *filt, struct knote *kn)
{
    if (linux_get_descriptor_type(kn) < 0)
        return (-1);

    /* Convert the kevent into an epoll_event */
#if defined(HAVE_EPOLLRDHUP)
    kn->data.events = EPOLLIN | EPOLLRDHUP;
#else
    kn->data.events = EPOLLIN;
#endif
    if (kn->kev.flags & EV_CLEAR)
        kn->data.events |= EPOLLET;

    /* Special case: for regular files, add a surrogate eventfd that is always readable */
    if (kn->kn_flags & KNFL_FILE) {
        int evfd;

        /*
         * We only set oneshot for cases where we're not going to
         * be using EPOLL_CTL_MOD.
         *
         * We rely on the common code disabling the event after
         * it's fired once.
         *
         * See this SO post for details:
         * https://stackoverflow.com/questions/59517961/how-should-i-use-epoll-to-read-and-write-from-the-same-fd
         */
        if (kn->kev.flags & EV_ONESHOT || kn->kev.flags & EV_DISPATCH)
            kn->data.events |= EPOLLONESHOT;

        kn->kn_epollfd = filter_epoll_fd(filt);
        evfd = eventfd(0, 0);
        if (evfd < 0) {
            dbg_perror("eventfd(2)");
            return (-1);
        }
        if (eventfd_write(evfd, 1) < 0) {
            dbg_perror("eventfd_write(3)");
            (void) close(evfd);
            return (-1);
        }

        kn->kdata.kn_eventfd = evfd;

        KN_UDATA(kn);   /* populate this knote's kn_udata field */
        if (epoll_ctl(kn->kn_epollfd, EPOLL_CTL_ADD, kn->kdata.kn_eventfd, EPOLL_EV_KN(kn->data.events, kn)) < 0) {
            dbg_printf("epoll_ctl(2): %s", strerror(errno));
            (void) close(evfd);
            return (-1);
        }

        kn->kn_registered = 1;

        return (0);
    }

    return epoll_update(EPOLL_CTL_ADD, filt, kn, kn->data.events, false);
}

int
evfilt_read_knote_modify(struct filter *filt, struct knote *kn,
        const struct kevent *kev)
{
    (void) filt;
    (void) kn;
    (void) kev;
    return (-1); /* STUB */
}

int
evfilt_read_knote_delete(struct filter *filt, struct knote *kn)
{
    if ((kn->kn_flags & KNFL_FILE) && (kn->kdata.kn_eventfd != -1)) {
        if (kn->kn_registered && epoll_ctl(kn->kn_epollfd, EPOLL_CTL_DEL, kn->kdata.kn_eventfd, NULL) < 0) {
            dbg_perror("epoll_ctl(2)");
            return (-1);
        }
        kn->kn_registered = 0;
        (void) close(kn->kdata.kn_eventfd);
        kn->kdata.kn_eventfd = -1;
        return (0);
    }

    return epoll_update(EPOLL_CTL_DEL, filt, kn, EPOLLIN, true);
}

int
evfilt_read_knote_enable(struct filter *filt, struct knote *kn)
{
    if (kn->kn_flags & KNFL_FILE) {
        if (epoll_ctl(kn->kn_epollfd, EPOLL_CTL_ADD, kn->kdata.kn_eventfd, EPOLL_EV_KN(kn->data.events, kn)) < 0) {
            dbg_perror("epoll_ctl(2)");
            return (-1);
        }
        kn->kn_registered = 1;
        return (0);
    }

    return epoll_update(EPOLL_CTL_ADD, filt, kn, kn->data.events, false);
}

int
evfilt_read_knote_disable(struct filter *filt, struct knote *kn)
{
    if (kn->kn_flags & KNFL_FILE) {
        if (epoll_ctl(kn->kn_epollfd, EPOLL_CTL_DEL, kn->kdata.kn_eventfd, NULL) < 0) {
            dbg_perror("epoll_ctl(2)");
            return (-1);
        }
        kn->kn_registered = 1;
        return (0);
    }

    return epoll_update(EPOLL_CTL_DEL, filt, kn, EPOLLIN, false);
}

const struct filter evfilt_read = {
    .kf_id      = EVFILT_READ,
    .kf_copyout = evfilt_read_copyout,
    .kn_create  = evfilt_read_knote_create,
    .kn_modify  = evfilt_read_knote_modify,
    .kn_delete  = evfilt_read_knote_delete,
    .kn_enable  = evfilt_read_knote_enable,
    .kn_disable = evfilt_read_knote_disable,
};
