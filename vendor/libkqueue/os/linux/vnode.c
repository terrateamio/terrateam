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
#include <pthread.h>
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/queue.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <string.h>
#include <unistd.h>

#include <limits.h>
#include <sys/inotify.h>
#include <sys/epoll.h>

#include "sys/event.h"
#include "private.h"

#define INEVT_MASK_DUMP(attrib) \
    if (evt->mask & attrib) \
       fputs(#attrib, stdout);

static void
inotify_event_dump(struct inotify_event *evt)
{
    fputs("[BEGIN: inotify_event dump]\n", stdout);
    fprintf(stdout, "  wd = %d\n", evt->wd);
    fprintf(stdout, "  mask = %o (", evt->mask);
    INEVT_MASK_DUMP(IN_ACCESS);
    INEVT_MASK_DUMP(IN_MODIFY);
    INEVT_MASK_DUMP(IN_ATTRIB);
    INEVT_MASK_DUMP(IN_CLOSE_WRITE);
    INEVT_MASK_DUMP(IN_CLOSE_NOWRITE);
    INEVT_MASK_DUMP(IN_OPEN);
    INEVT_MASK_DUMP(IN_MOVED_FROM);
    INEVT_MASK_DUMP(IN_MOVED_TO);
    INEVT_MASK_DUMP(IN_CREATE);
    INEVT_MASK_DUMP(IN_DELETE);
    INEVT_MASK_DUMP(IN_DELETE_SELF);
    INEVT_MASK_DUMP(IN_MOVE_SELF);
    fputs(")\n", stdout);
    fputs("[END: inotify_event dump]\n", stdout);
    fflush(stdout);
}

static int
fd_to_path(char *buf, size_t bufsz, int fd)
{
    char path[1024];    //TODO: Maxpathlen, etc.

    if (snprintf(&path[0], sizeof(path), "/proc/%d/fd/%d", getpid(), fd) < 0)
        return (-1);

    memset(buf, 0, bufsz);
    return (readlink(path, buf, bufsz));
}

 
int
evfilt_vnode_init(struct filter *filt)
{
    filt->kf_pfd = inotify_init();
    dbg_printf("inotify fd = %d", filt->kf_pfd);
    if (filt->kf_pfd < 0)
        return (-1);

    return (0);
}

void
evfilt_vnode_destroy(struct filter *filt)
{
    close(filt->kf_pfd);
}

int
evfilt_vnode_copyin(struct filter *filt, 
        struct knote *dst, const struct kevent *src)
{
    char path[1024];        //FIXME: maxpathlen
    int rv;
    uint32_t mask;

    if (src->flags & EV_DELETE) {
        dbg_puts("hi");
        if (inotify_rm_watch(filt->kf_pfd, dst->kev.data) < 0) {
            dbg_printf("inotify_rm_watch(2): %s", strerror(errno));
            return (-1);
        } else {
            return (0);
        }
    }

    if (src->flags & EV_ADD && KNOTE_EMPTY(dst)) {
        memcpy(&dst->kev, src, sizeof(*src));
        if (fd_to_path(&path[0], sizeof(path), src->ident) < 0)
            return (-1);

        /* Convert the fflags to the inotify mask */
        mask = 0;

        /* FIXME: buggy inotify will not send IN_DELETE events
           if the application has the file opened.
See: http://lists.schmorp.de/pipermail/libev/2008q4/000443.html
           Need to proccess this case during copyout.

           Actually it seems that IN_DELETE | IN_DELETE_SELF is only
            returned when watching directories; when watching
             files, IN_ATTRIB seems to be returned only.
        */
        if (src->fflags & NOTE_DELETE)
            mask |= IN_ATTRIB | IN_DELETE | IN_DELETE_SELF;

        if (src->flags & EV_ONESHOT)
            mask |= IN_ONESHOT;
#if FIXME
        if (src->flags & EV_CLEAR)
            ev.events |= EPOLLET;
#endif
        dbg_printf("inotify_add_watch(2); inofd=%d, mask=%d, path=%s", 
                filt->kf_pfd, mask, path);
        rv = inotify_add_watch(filt->kf_pfd, path, mask);
        if (rv < 0) {
            dbg_printf("inotify_add_watch(2): %s", strerror(errno));
            return (-1);
        } else {
            dbg_printf("watch descriptor = %d", rv);
            dst->kev.data = rv;
            return (0);
        }

    }
    if (src->flags & EV_ENABLE || src->flags & EV_DISABLE) {
        abort();
        //FIXME todo
    }

    //REFACTOR this
    return (0);
}

int
evfilt_vnode_copyout(struct filter *filt, 
            struct kevent *dst, 
            int nevents)
{
    struct inotify_event inevt[MAX_KEVENT];
    struct knote *kn;
    struct stat sb;
    ssize_t n;
    int i;

    dbg_puts("draining inotify events");
    for (;;) {
        n = read(filt->kf_pfd, &inevt[0], nevents * sizeof(inevt[0]));
        if (n < 0) {
            if (errno == EINTR)
                continue;
            dbg_perror("read");
            return (-1);
        } else {
            break;
        }
    }
    dbg_printf("read(2) from inotify wd: %zu bytes", n);

    for (i = 0, nevents = 0; i < n; i++) {
        if (inevt[i].wd == 0)
            break;
        inotify_event_dump(&inevt[i]);
        /* FIXME: support variable-length structures.. */
        if (inevt[i].len != 0) 
            abort();

        kn = knote_lookup_data(filt, inevt[i].wd);
        if (kn != NULL) {
            kevent_dump(&kn->kev);
            dst->ident = kn->kev.ident;
            dst->filter = kn->kev.filter;
            dst->udata = kn->kev.udata;

            /* FIXME: this is wrong. See the manpage */
            dst->flags = 0; 
            dst->fflags = 0;
            dst->data = 0;

            /* NOTE: unavoidable filesystem race here */
            if (kn->kev.fflags & EV_DELETE) {
                if (fstat(kn->kev.ident, &sb) < 0) {
                    /* TODO: handle signals */
                    dbg_puts("woot!");
                    dst->fflags = EV_DELETE;
                } else {
                    dbg_printf("link count = %zu", sb.st_nlink);
                    if (sb.st_nlink == 0) {
                        dbg_puts("woot! woot!");
                        dst->fflags = EV_DELETE;
                    } else {
                    /* FIXME: not delete.. maybe ATTRIB event */
                    }
                }
            }

            nevents++;
            dst++;
        } else {
            dbg_printf("no match for wd # %d", inevt[i].wd);
        }
    }

    return (nevents);
}

const struct filter evfilt_vnode = {
    EVFILT_VNODE,
    evfilt_vnode_init,
    evfilt_vnode_destroy,
    evfilt_vnode_copyin,
    evfilt_vnode_copyout,
};
