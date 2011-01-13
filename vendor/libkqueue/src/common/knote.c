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
#include <sys/types.h>

#include "private.h"

static int
knote_cmp(struct knote *a, struct knote *b)
{
    return memcmp(&a->kev.ident, &b->kev.ident, sizeof(a->kev.ident)); 
}

RB_GENERATE(knt, knote, kntree_ent, knote_cmp)

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
    RB_INSERT(knt, &filt->kf_knote, kn);
}

void
knote_free(struct filter *filt, struct knote *kn)
{
    dbg_printf("filter=%s, ident=%u",
            filter_name(kn->kev.filter), (unsigned int) kn->kev.ident);
	RB_REMOVE(knt, &filt->kf_knote, kn);
    if (kn->event_ent.tqe_prev) //XXX-FIXME what if this is the 1st entry??
        TAILQ_REMOVE(&filt->kf_event, kn, event_ent);
    filt->kn_delete(filt, kn);
	free(kn);
}

void
knote_free_all(struct filter *filt)
{
    struct knote *n1, *n2;

    /* Destroy all pending events */
    for (n1 = TAILQ_FIRST(&filt->kf_event); n1 != NULL; n1 = n2) {
        n2 = TAILQ_NEXT(n1, event_ent);
        free(n1);
    }

    /* Distroy all knotes */
    for (n1 = RB_MIN(knt, &filt->kf_knote); n1 != NULL; n1 = n2) {
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
    ent = RB_FIND(knt, &filt->kf_knote, &query);

    dbg_printf("id=%d ent=%p", ident, ent);

    return (ent);
}
    
struct knote *
knote_lookup_data(struct filter *filt, intptr_t data)
{
    struct knote *kn;

    RB_FOREACH(kn, knt, &filt->kf_knote) {
        if (data == kn->kev.data) 
            break;
    }
    return (kn);
}

void
knote_enqueue(struct filter *filt, struct knote *kn)
{
    /* Prevent a knote from being enqueued() multiple times */
    if (kn->event_ent.tqe_next == NULL && kn->event_ent.tqe_prev == NULL)
        TAILQ_INSERT_TAIL(&filt->kf_event, kn, event_ent);
}

struct knote *
knote_dequeue(struct filter *filt)
{
    struct knote *kn;

    if (TAILQ_EMPTY(&filt->kf_event)) {
        kn = NULL;
        dbg_puts("no events are pending");
    } else {
        kn = TAILQ_FIRST(&filt->kf_event);
        TAILQ_REMOVE(&filt->kf_event, kn, event_ent);
        memset(&kn->event_ent, 0, sizeof(kn->event_ent));
    }

    return (kn);
}

int
knote_events_pending(struct filter *filt)
{
    int res;

    res = TAILQ_EMPTY(&filt->kf_event);

    return (res);
}

/*
 * Test if a socket is active or passive.
 */
int
knote_get_socket_type(struct knote *kn)
{
    socklen_t slen;
    int i, lsock;

    slen = sizeof(lsock);
    lsock = 0;
    i = getsockopt(kn->kev.ident, SOL_SOCKET, SO_ACCEPTCONN, &lsock, &slen);
    if (i < 0) {
        switch (errno) {
            case ENOTSOCK:   /* same as lsock = 0 */
                return (0);
                break;
            default:
                dbg_printf("getsockopt(3) failed: %s", strerror(errno));
                return (-1);
        }
    } else {
        if (lsock) 
            kn->flags |= KNFL_PASSIVE_SOCKET;
        return (0);
    }
}
