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

struct knote *
knote_new(void)
{
    struct knote *dst;

    if ((dst = calloc(1, sizeof(*dst))) == NULL) 
        return (NULL);

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
	RB_REMOVE(knt, &filt->kf_knote, kn);
    if (kn->event_ent.tqe_prev) //XXX-FIXME what if this is the 1st entry??
        TAILQ_REMOVE(&filt->kf_event, kn, event_ent);
    pthread_rwlock_unlock(&filt->kf_mtx);
    filt->kn_delete(filt, kn);
	free(kn);
}

void
knote_free_all(struct filter *filt)
{
    struct knote *n1, *n2;

    /* Destroy all pending events */
    for (n1 = TAILQ_FIRST(&filt->kf_event); 
            n1 != NULL; n1 = n2) 
    {
        n2 = TAILQ_NEXT(n1, event_ent);
        free(n1);
    }

    /* Distroy all knotes */
    for (n1 = RB_MIN(knt, &filt->kf_knote); 
            n1 != NULL; 
            n1 = RB_NEXT(knt, filt->kf_knote, n1))
    {
        n2 = RB_NEXT(knt, filt->kf_knote, n1);
        RB_REMOVE(knt, &filt->kf_knote, n1);
        free(n1);
    }
}

/* TODO: rename to knote_lookup_ident */
struct knote *
knote_lookup(struct filter *filt, short ident)
{
    struct knote query;
    struct knote *ent = NULL;

    query.kev.ident = ident;
    pthread_rwlock_rdlock(&filt->kf_mtx);
    ent = RB_FIND(knt, &filt->kf_knote, &query);
    pthread_rwlock_unlock(&filt->kf_mtx);

    dbg_printf("id=%d ent=%p", ident, ent);

    return (ent);
}
    
struct knote *
knote_lookup_data(struct filter *filt, intptr_t data)
{
    struct knote *kn;

    pthread_rwlock_rdlock(&filt->kf_mtx);
    RB_FOREACH(kn, knt, &filt->kf_knote) {
        if (data == kn->kev.data) 
            break;
    }
    pthread_rwlock_unlock(&filt->kf_mtx);
    return (kn);
}

void
knote_enqueue(struct filter *filt, struct knote *kn)
{
    /* XXX-FIXME: check if the knote is already on the eventlist */
    dbg_printf("id=%ld", kn->kev.ident);
    pthread_rwlock_wrlock(&filt->kf_mtx);
    TAILQ_INSERT_TAIL(&filt->kf_event, kn, event_ent);
    pthread_rwlock_unlock(&filt->kf_mtx);
}

struct knote *
knote_dequeue(struct filter *filt)
{
    struct knote *kn;

    pthread_rwlock_wrlock(&filt->kf_mtx);
    if (TAILQ_EMPTY(&filt->kf_event)) {
        kn = NULL;
        dbg_puts("no events are pending");
    } else {
        kn = TAILQ_FIRST(&filt->kf_event);
        TAILQ_REMOVE(&filt->kf_event, kn, event_ent);
        memset(&kn->event_ent, 0, sizeof(kn->event_ent));
        dbg_printf("id=%ld", kn->kev.ident);
    }
    pthread_rwlock_unlock(&filt->kf_mtx);

    return (kn);
}

int
knote_events_pending(struct filter *filt)
{
    int res;

    pthread_rwlock_rdlock(&filt->kf_mtx);
    res = TAILQ_EMPTY(&filt->kf_event);
    pthread_rwlock_unlock(&filt->kf_mtx);

    return (res);
}
