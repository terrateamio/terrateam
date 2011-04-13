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
#include "alloc.h"

static void knote_free(struct filter *, struct knote *);

int
knote_init(void)
{
    return 0;
//    return (mem_init(sizeof(struct knote), 1024));
}

static int
knote_cmp(struct knote *a, struct knote *b)
{
    return memcmp(&a->kev.ident, &b->kev.ident, sizeof(a->kev.ident)); 
}

RB_GENERATE(knt, knote, kntree_ent, knote_cmp)

struct knote *
knote_new(void)
{
	// struct knote* res = return (mem_calloc());
	struct knote* res = malloc(sizeof(struct knote));
	if(!res) return NULL;

	if(pthread_mutex_init(&res->mtx, NULL)){
		dbg_perror("pthread_mutex_init");
		free(res);
		return NULL;
	}

    return res;
}

static inline void
knote_retain(struct knote *kn)
{
    atomic_inc(&kn->kn_ref);
}

void
knote_release(struct filter *filt, struct knote *kn)
{
    int ref;

    ref = atomic_dec(&kn->kn_ref);
    if (ref <= 0) {
        dbg_printf("freeing knote at %p, rc=%d", kn, ref);
        pthread_rwlock_wrlock(&filt->kf_knote_mtx);
        knote_free(filt, kn);
        pthread_rwlock_unlock(&filt->kf_knote_mtx);
    } else {
        dbg_printf("NOT freeing knote %p rc=%d", kn, ref);
    }
}

void
knote_insert(struct filter *filt, struct knote *kn)
{
    pthread_rwlock_wrlock(&filt->kf_knote_mtx);
    RB_INSERT(knt, &filt->kf_knote, kn);
    pthread_rwlock_unlock(&filt->kf_knote_mtx);
}

static void
knote_free(struct filter *filt, struct knote *kn)
{
    RB_REMOVE(knt, &filt->kf_knote, kn);
    filt->kn_delete(filt, kn);
    pthread_mutex_destroy(&kn->mtx);
    free(kn);
//    mem_free(kn);
}

/* XXX-FIXME this is broken and should be removed */
void
knote_free_all(struct filter *filt)
{
    struct knote *n1, *n2;

    abort();

    /* Destroy all knotes */
    pthread_rwlock_wrlock(&filt->kf_knote_mtx);
    for (n1 = RB_MIN(knt, &filt->kf_knote); n1 != NULL; n1 = n2) {
        n2 = RB_NEXT(knt, filt->kf_knote, n1);
        RB_REMOVE(knt, &filt->kf_knote, n1);
        free(n1);
    }
    pthread_rwlock_unlock(&filt->kf_knote_mtx);
}

/* TODO: rename to knote_lookup_ident */
struct knote *
knote_lookup(struct filter *filt, short ident)
{
    struct knote query;
    struct knote *ent = NULL;

    query.kev.ident = ident;

    pthread_rwlock_rdlock(&filt->kf_knote_mtx);
    ent = RB_FIND(knt, &filt->kf_knote, &query);
    if (ent != NULL) 
        knote_lock(ent);
    pthread_rwlock_unlock(&filt->kf_knote_mtx);

    dbg_printf("id=%d ent=%p", ident, ent);

    return (ent);
}
    
struct knote *
knote_lookup_data(struct filter *filt, intptr_t data)
{
    struct knote *kn;

    pthread_rwlock_rdlock(&filt->kf_knote_mtx);
    RB_FOREACH(kn, knt, &filt->kf_knote) {
        if (data == kn->kev.data) 
            break;
    }
    if (kn != NULL)
        knote_lock(kn);
    pthread_rwlock_unlock(&filt->kf_knote_mtx);

    return (kn);
}

int
knote_disable(struct filter *filt, struct knote *kn)
{
    assert(!(kn->kev.flags & EV_DISABLE));

    filt->kn_disable(filt, kn); //TODO: Error checking
    KNOTE_DISABLE(kn);
    return (0);
}

//TODO: knote_enable()
