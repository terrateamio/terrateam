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

static int
knote_cmp(struct knote *a, struct knote *b)
{
    return memcmp(&a->kev.ident, &b->kev.ident, sizeof(a->kev.ident)); 
}

RB_GENERATE(knt, knote, kntree_ent, knote_cmp);

/* TODO: These must be called with the kqueue lock held */

struct knote *
knote_new(struct filter *filt)
{
    struct knote *dst;

    if ((dst = calloc(1, sizeof(*dst))) == NULL) 
        return (NULL);

    /* LEGACY */
    pthread_rwlock_wrlock(&filt->kf_mtx);
    KNOTE_INSERT(&filt->kf_watchlist, dst);
    pthread_rwlock_unlock(&filt->kf_mtx);

    return (dst);
}

void
knote_insert(struct filter *filt, struct knote *kn)
{
    pthread_rwlock_wrlock(&filt->kf_mtx);
    RB_INSERT(knt, &filt->kf_knote, kn);
    pthread_rwlock_unlock(&filt->kf_mtx);
}

void
knote_free(struct filter *filt, struct knote *kn)
{
    dbg_printf("filter=%s, ident=%u",
            filter_name(kn->kev.filter), (u_int) kn->kev.ident);
    pthread_rwlock_wrlock(&filt->kf_mtx);
	LIST_REMOVE(kn, entries);   //DEADWOOD
	RB_REMOVE(knt, &filt->kf_knote, kn);
    /* XXX-FIXME Remove from eventlist */
    pthread_rwlock_unlock(&filt->kf_mtx);
	free(kn);
}

/* TODO: rename to knote_lookup_ident */
struct knote *
knote_lookup(struct filter *filt, short ident)
{
    struct knote *kn;

    pthread_rwlock_rdlock(&filt->kf_mtx);
    /* TODO: Use rbtree for faster searching */
    LIST_FOREACH(kn, &filt->kf_watchlist, entries) {
        if (ident == kn->kev.ident)
            goto knote_found;
    }
    LIST_FOREACH(kn, &filt->kf_eventlist, entries) {
        if (ident == kn->kev.ident)
            goto knote_found;
    }
    pthread_rwlock_unlock(&filt->kf_mtx);
    return (NULL);

knote_found:
    pthread_rwlock_unlock(&filt->kf_mtx);
    return (kn);
}
    
struct knote *
knote_lookup_data(struct filter *filt, intptr_t data)
{
    struct knote *kn;

    pthread_rwlock_rdlock(&filt->kf_mtx);
    LIST_FOREACH(kn, &filt->kf_watchlist, entries) {
        if (data == kn->kev.data)
            goto knote_found;
    }
    LIST_FOREACH(kn, &filt->kf_eventlist, entries) {
        if (data == kn->kev.data)
            goto knote_found;
    }
    pthread_rwlock_unlock(&filt->kf_mtx);
    return (NULL);

knote_found:
    pthread_rwlock_unlock(&filt->kf_mtx);
    return (kn);
}

void
knote_enqueue(struct filter *filt, struct knote *kn)
{
    /* FIXME: check if the knote is already on the eventlist */
    dbg_printf("id=%ld", kn->kev.ident);
    LIST_INSERT_HEAD(&filt->kf_event, kn, event_ent);
}

struct knote *
knote_dequeue(struct filter *filt)
{
    struct knote *kn;

    if (LIST_EMPTY(&filt->kf_event)) 
        return (NULL);

    kn = LIST_FIRST(&filt->kf_event);
    LIST_REMOVE(kn, event_ent);
    dbg_printf("id=%ld", kn->kev.ident);

    return (kn);
}
