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

#include <inttypes.h>

#include "private.h"

#include "alloc.h"

/** Comparator for the knote_index
 *
 * FIXME - Should respect EV_UDATA_SPECIFIC but that's a whole
 * lot of additional work.
 *
 * @param[in] a    First knote to compare.
 * @param[in] b    Second knote to compare.
 * @return
 *    - +1 if a's ident is > than b's.
 *    - 0 if a and b's ident are equal.
 *    - -1 if a's ident is < than b's.
 */
static int
knote_cmp(struct knote *a, struct knote *b)
{
    return (a->kev.ident > b->kev.ident) - (a->kev.ident < b->kev.ident);
}

RB_GENERATE(knote_index, knote, kn_index, knote_cmp)

struct knote *
knote_new(void)
{
    struct knote *res;

    res = calloc(1, sizeof(struct knote));
    if (res == NULL)
        return (NULL);

    res->kn_ref = 1;

    return (res);
}

void
knote_release(struct knote *kn)
{
    assert (kn->kn_ref > 0);

    if (atomic_dec(&kn->kn_ref) == 0) {
        if (kn->kn_flags & KNFL_KNOTE_DELETED) {
            dbg_printf("kn=%p - freeing", kn);
#ifndef NDEBUG
            memset(kn, 0x42, sizeof(*kn));
#endif
            free(kn);
        } else {
            dbg_puts("kn=%p - attempted to free knote without marking it as deleted");
        }
    } else {
        dbg_printf("kn=%p rc=%d - decrementing refcount", kn, kn->kn_ref);
    }
}

void
knote_insert(struct filter *filt, struct knote *kn)
{
    kqueue_mutex_assert(filt->kf_kqueue, MTX_LOCKED);
    RB_INSERT(knote_index, &filt->kf_index, kn);
}

struct knote *
knote_lookup(struct filter *filt, uintptr_t ident)
{
    struct knote query;
    struct knote *ent = NULL;

    query.kev.ident = ident;

    kqueue_mutex_assert(filt->kf_kqueue, MTX_LOCKED);
    ent = RB_FIND(knote_index, &filt->kf_index, &query);

    return (ent);
}

int knote_delete_all(struct filter *filt)
{
    struct knote *kn, *tmp;

    kqueue_mutex_assert(filt->kf_kqueue, MTX_LOCKED);
    RB_FOREACH_SAFE(kn, knote_index, &filt->kf_index, tmp)
        knote_delete(filt, kn);

    return (0);
}

int knote_mark_disabled_all(struct filter *filt)
{
    struct knote *kn, *tmp;

    RB_FOREACH_SAFE(kn, knote_index, &filt->kf_index, tmp) {
        dbg_printf("kn=%p - marking disabled", kn);
        KNOTE_DISABLE(kn);
    }

    return (0);
}

int
knote_delete(struct filter *filt, struct knote *kn)
{
    struct knote query;
    struct knote *tmp;
    int rv;

    dbg_printf("kn=%p - calling kn_delete", kn);
    if (kn->kn_flags & KNFL_KNOTE_DELETED) {
        dbg_printf("kn=%p - double deletion detected", kn);
        return (-1);
    }

    /*
     * Verify that the knote wasn't removed by another
     * thread before we acquired the knotelist lock.
     */
    query.kev.ident = kn->kev.ident;
    kqueue_mutex_assert(filt->kf_kqueue, MTX_LOCKED);
    tmp = RB_FIND(knote_index, &filt->kf_index, &query);
    if (tmp != kn)
        dbg_printf("kn=%p - conflicting entry in filter tree", kn);

    RB_REMOVE(knote_index, &filt->kf_index, kn);

    if (LIST_INSERTED(kn, kn_ready))
        LIST_REMOVE_ZERO(kn, kn_ready);

    rv = filt->kn_delete(filt, kn);
    dbg_printf("kn=%p - kn_delete rv=%i", kn, rv);

    kn->kn_flags |= KNFL_KNOTE_DELETED;
    knote_release(kn);

    return (rv);
}

int
knote_disable(struct filter *filt, struct knote *kn)
{
    int rv = 0;

    /* If the knote is already disabled, this call is a noop */
    if (KNOTE_DISABLED(kn))
        return (0);

    dbg_printf("kn=%p - calling kn_disable", kn);
    rv = filt->kn_disable(filt, kn);
    dbg_printf("kn=%p - kn_disable rv=%i", kn, rv);
    if (rv == 0) {
        kqueue_mutex_assert(filt->kf_kqueue, MTX_LOCKED);
        if (LIST_INSERTED(kn, kn_ready)) /* No longer marked as ready if disabled */
            LIST_REMOVE_ZERO(kn, kn_ready);
        KNOTE_DISABLE(kn); /* set the disable flag */
    }

    return (rv);
}

int
knote_enable(struct filter *filt, struct knote *kn)
{
    int rv = 0;

    /* If the knote is already enabled, this call is a noop */
    if (KNOTE_ENABLED(kn))
        return (0);

    dbg_printf("kn=%p - calling kn_enable", kn);
    rv = filt->kn_enable(filt, kn);
    dbg_printf("kn=%p - kn_enable rv=%i", kn, rv);
    if (rv == 0) KNOTE_ENABLE(kn);
    return (rv);
}
