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

#include <stdlib.h>
#include <string.h>
#include <sys/queue.h>
#include <unistd.h>

#include "private.h"

/* TODO: These must be called with the kqueue lock held */

struct knote *
knote_new(struct filter *filt)
{
    struct knote *dst;

    if ((dst = calloc(1, sizeof(*dst))) == NULL) 
        return (NULL);
    KNOTE_INSERT(&filt->kf_watchlist, dst);
    return (dst);
}

void
knote_free(struct knote *kn)
{
    dbg_printf("knote_free(): filt=%d, ident=%u",
            kn->kev.filter, (u_int) kn->kev.ident);
	LIST_REMOVE(kn, entries);
	free(kn);
}

/* TODO: rename to knote_lookup_ident */
struct knote *
knote_lookup(struct filter *filt, short ident)
{
    struct knote *kn;

    /* TODO: Use rbtree for faster searching */
    LIST_FOREACH(kn, &filt->kf_watchlist, entries) {
        if (ident == kn->kev.ident)
            return (kn);
    }
    LIST_FOREACH(kn, &filt->kf_eventlist, entries) {
        if (ident == kn->kev.ident)
            return (kn);
    }

    return (NULL);
}
    
struct knote *
knote_lookup_data(struct filter *filt, intptr_t data)
{
    struct knote *kn;

    LIST_FOREACH(kn, &filt->kf_watchlist, entries) {
        if (data == kn->kev.data)
            return (kn);
    }
    LIST_FOREACH(kn, &filt->kf_eventlist, entries) {
        if (data == kn->kev.data)
            return (kn);
    }

    return (NULL);
}
