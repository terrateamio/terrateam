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

#include "sys/event.h"
#include "private.h"

int
evfilt_vnode_init(struct filter *filt)
{
    return (-1);
}

void
evfilt_vnode_destroy(struct filter *filt)
{
    ;
}

int
evfilt_vnode_copyin(struct filter *filt, 
        struct knote *dst, const struct kevent *src)
{
#if TODO
    char path[PATH_MAX];
    struct stat sb;
    uint32_t mask;

    if (src->flags & EV_DELETE || src->flags & EV_DISABLE)
        return delete_watch(filt->kf_pfd, dst);

    if (src->flags & EV_ADD && KNOTE_EMPTY(dst)) {
        memcpy(&dst->kev, src, sizeof(*src));
        if (fstat(src->ident, &sb) < 0) {
            dbg_puts("fstat failed");
            return (-1);
        }
        dst->kn_st_nlink = sb.st_nlink;
        dst->kn_st_size = sb.st_size;
        dst->kev.data = -1;
    }

    if (src->flags & EV_ADD || src->flags & EV_ENABLE) {

        /* Convert the fd to a pathname */
        if (fd_to_path(&path[0], sizeof(path), src->ident) < 0)
            return (-1);

        /* Convert the fflags to the inotify mask */
        mask = 0;
        if (dst->kev.fflags & NOTE_DELETE)
            mask |= IN_ATTRIB | IN_DELETE_SELF;
        if (dst->kev.fflags & NOTE_WRITE)      
            mask |= IN_MODIFY | IN_ATTRIB;
        if (dst->kev.fflags & NOTE_EXTEND)
            mask |= IN_MODIFY | IN_ATTRIB;
        if ((dst->kev.fflags & NOTE_ATTRIB) || 
            (dst->kev.fflags & NOTE_LINK))
            mask |= IN_ATTRIB;
        if (dst->kev.fflags & NOTE_RENAME)
            mask |= IN_MOVE_SELF;
        if (dst->kev.flags & EV_ONESHOT)
            mask |= IN_ONESHOT;

        dbg_printf("inotify_add_watch(2); inofd=%d, %s, path=%s", 
                filt->kf_pfd, inotify_mask_dump(mask), path);
        dst->kev.data = inotify_add_watch(filt->kf_pfd, path, mask);
        if (dst->kev.data < 0) {
            dbg_printf("inotify_add_watch(2): %s", strerror(errno));
            return (-1);
        }
    }

    return (0);
#endif
    return (-1);
}

int
evfilt_vnode_copyout(struct filter *filt, 
            struct kevent *dst, 
            int nevents)
{
#if TODO
    struct inotify_event evt;
    struct stat sb;
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

    memcpy(dst, &kn->kev, sizeof(*dst));
    dst->data = 0;

    /* No error checking because fstat(2) should rarely fail */
    if ((evt.mask & IN_ATTRIB || evt.mask & IN_MODIFY) 
        && fstat(kn->kev.ident, &sb) == 0) {
        if (sb.st_nlink == 0 && kn->kev.fflags & NOTE_DELETE) 
            dst->fflags |= NOTE_DELETE;
        if (sb.st_nlink != kn->kn_st_nlink && kn->kev.fflags & NOTE_LINK) 
            dst->fflags |= NOTE_LINK;
#if HAVE_NOTE_TRUNCATE
        if (sb.st_nsize == 0 && kn->kev.fflags & NOTE_TRUNCATE) 
            dst->fflags |= NOTE_TRUNCATE;
#endif
        if (sb.st_size > kn->kn_st_size && kn->kev.fflags & NOTE_WRITE) 
            dst->fflags |= NOTE_EXTEND;
       kn->kn_st_nlink = sb.st_nlink;
       kn->kn_st_size = sb.st_size;
    }

    if (evt.mask & IN_MODIFY && kn->kev.fflags & NOTE_WRITE) 
        dst->fflags |= NOTE_WRITE;
    if (evt.mask & IN_ATTRIB && kn->kev.fflags & NOTE_ATTRIB) 
        dst->fflags |= NOTE_ATTRIB;
    if (evt.mask & IN_MOVE_SELF && kn->kev.fflags & NOTE_RENAME) 
        dst->fflags |= NOTE_RENAME;
    if (evt.mask & IN_DELETE_SELF && kn->kev.fflags & NOTE_DELETE) 
        dst->fflags |= NOTE_DELETE;

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
#endif
    return (-1);
}

const struct filter evfilt_vnode = {
    0, //EVFILT_VNODE,
    evfilt_vnode_init,
    evfilt_vnode_destroy,
    evfilt_vnode_copyin,
    evfilt_vnode_copyout,
};
