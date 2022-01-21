/*
 * Copyright (c) 2022 Arran Cudbard-Bell <a.cudbardb@freeradius.org>
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
#include "private.h"

int
common_libkqueue_knote_create(struct filter *filt, struct knote *kn)
{
    kn->kev.flags |= EV_RECEIPT; /* Causes the knote to be copied to the eventlist */

    switch (kn->kev.fflags) {
    case NOTE_VERSION_STR:
        kn->kev.udata = LIBKQUEUE_VERSION_STRING
#  ifdef LIBKQUEUE_VERSION_RELEASE
                "-" STRINGIFY(LIBKQUEUE_VERSION_RELEASE)
#  endif
#  ifdef LIBKQUEUE_VERSION_COMMIT
		" (git #"LIBKQUEUE_VERSION_COMMIT")"
#  endif
#  ifdef LIBKQUEUE_VERSION_DATE
		" built "LIBKQUEUE_VERSION_DATE
#  endif
                ;
        break;

    case NOTE_VERSION:
         kn->kev.data = ((uint32_t)LIBKQUEUE_VERSION_MAJOR << 24) |
                        ((uint32_t)LIBKQUEUE_VERSION_MINOR << 16) |
                        ((uint32_t)LIBKQUEUE_VERSION_PATCH << 8)
#ifdef LIBKQUEUE_VERSION_RELEASE
                        | (uint32_t)LIBKQUEUE_VERSION_RELEASE
#endif
                ;
         break;

    default:
        return (-1);
    }

    return (1); /* Provide receipt */
}

int
common_libkqueue_knote_copyout(UNUSED struct kevent *dst, UNUSED int nevents, UNUSED struct filter *filt,
    UNUSED struct knote *kn, UNUSED void *ev)
{
    return (-1);
}

int
common_libkqueue_knote_modify(struct filter *filt, struct knote *kn, const struct kevent *kev)
{
    memcpy(&kn->kev, kev, sizeof(kn->kev));
    return common_libkqueue_knote_create(filt, kn);
}

int
common_libkqueue_knote_delete(UNUSED struct filter *filt, UNUSED struct knote *kn)
{
    return (0);
}

int
common_libkqueue_knote_enable(UNUSED struct filter *filt, UNUSED struct knote *kn)
{
    return (0);
}

int
common_libkqueue_knote_disable(UNUSED struct filter *filt, UNUSED struct knote *kn)
{
    return (0);
}

const struct filter evfilt_libkqueue = {
    .kf_id      = EVFILT_LIBKQUEUE,
    .kf_copyout = common_libkqueue_knote_copyout,
    .kn_create  = common_libkqueue_knote_create,
    .kn_modify  = common_libkqueue_knote_modify,
    .kn_delete  = common_libkqueue_knote_delete,
    .kn_enable  = common_libkqueue_knote_enable,
    .kn_disable = common_libkqueue_knote_disable
};
