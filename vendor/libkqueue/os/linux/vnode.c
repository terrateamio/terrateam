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
#include <err.h>
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


/* TODO: USE this to get events with name field */
int
get_one_event(struct inotify_event *dst, int pfd)
{
    ssize_t n;

    dbg_puts("reading one inotify event");
    for (;;) {
        n = read(pfd, dst, sizeof(*dst));
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

    /* FIXME-TODO: if len > 0, read(len) */
    if (dst->len != 0) 
        abort();


    return (0);
}

static int
delete_watch(int pfd, struct knote *kn)
{
    if (kn->kev.data < 0) 
        return (0);
    if (inotify_rm_watch(pfd, kn->kev.data) < 0) {
        dbg_printf("inotify_rm_watch(2): %s", strerror(errno));
        return (-1);
    }
    dbg_printf("wd %d removed", (int) kn->kev.data);
    kn->kev.data = -1;

    return (0);
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
    char path[PATH_MAX];
    uint32_t mask;

    if (src->flags & EV_DELETE || src->flags & EV_DISABLE)
        return delete_watch(filt->kf_pfd, dst);

    if (src->flags & EV_ADD && KNOTE_EMPTY(dst)) {
        memcpy(&dst->kev, src, sizeof(*src));
        dst->kev.flags |= EV_CLEAR;
        dst->kev.data = -1;
    }

    if (src->flags & EV_ADD || src->flags & EV_ENABLE) {

        /* Convert the fd to a pathname */
        if (fd_to_path(&path[0], sizeof(path), src->ident) < 0)
            return (-1);

        /* Convert the fflags to the inotify mask */
        mask = 0;
        if (dst->kev.fflags & NOTE_DELETE)
            mask |= IN_DELETE_SELF;
        if (dst->kev.fflags & NOTE_WRITE)
            mask |= IN_MODIFY;
        if (dst->kev.fflags & NOTE_ATTRIB)
            mask |= IN_ATTRIB;
        if (dst->kev.fflags & NOTE_RENAME)
            mask |= IN_MOVE_SELF;
        if (dst->kev.flags & EV_ONESHOT)
            mask |= IN_ONESHOT;

        dbg_printf("inotify_add_watch(2); inofd=%d, mask=%d, path=%s", 
                filt->kf_pfd, mask, path);
        dst->kev.data = inotify_add_watch(filt->kf_pfd, path, mask);
        if (dst->kev.data < 0) {
            dbg_printf("inotify_add_watch(2): %s", strerror(errno));
            return (-1);
        }
    }

    return (0);
}

int
evfilt_vnode_copyout(struct filter *filt, 
            struct kevent *dst, 
            int nevents)
{
    struct inotify_event evt;
    struct knote *kn;

    if (get_one_event(&evt, filt->kf_pfd) < 0)
        return (-1);

    inotify_event_dump(&evt);
    if (evt.mask & IN_IGNORED) {
        /* TODO: possibly return error when fs is unmounted */
        return (0);
    }

    kn = knote_lookup_data(filt, evt.wd);
    if (kn == NULL) {
        dbg_printf("no match for wd # %d", evt.wd);
        return (-1);
    }

    kevent_dump(&kn->kev);
    dst->ident = kn->kev.ident;
    dst->filter = kn->kev.filter;
    dst->udata = kn->kev.udata;
    dst->flags = 0; 
    dst->fflags = 0;

    if (evt.mask & IN_MODIFY && kn->kev.fflags & NOTE_WRITE) 
        dst->fflags |= NOTE_WRITE;
    if (evt.mask & IN_ATTRIB && kn->kev.fflags & NOTE_ATTRIB) 
        dst->fflags |= NOTE_ATTRIB;
    if (evt.mask & IN_MOVE_SELF && kn->kev.fflags & NOTE_RENAME) 
        dst->fflags |= NOTE_RENAME;
    if (evt.mask & IN_DELETE_SELF && kn->kev.fflags & NOTE_DELETE) 
        dst->fflags |= NOTE_DELETE;

    if (kn->kev.flags & EV_DISPATCH) {
        delete_watch(filt->kf_pfd, kn); /* TODO: error checking */
        KNOTE_DISABLE(kn);
    }
    if (kn->kev.flags & EV_ONESHOT) 
        knote_free(kn);
            
    return (1);
}

const struct filter evfilt_vnode = {
    EVFILT_VNODE,
    evfilt_vnode_init,
    evfilt_vnode_destroy,
    evfilt_vnode_copyin,
    evfilt_vnode_copyout,
};
