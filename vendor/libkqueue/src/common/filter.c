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

#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "private.h"

extern const struct filter evfilt_read;
extern const struct filter evfilt_write;
extern const struct filter evfilt_signal;
extern const struct filter evfilt_vnode;
extern const struct filter evfilt_proc;
extern const struct filter evfilt_timer;
extern const struct filter evfilt_user;

static int
filter_register(struct kqueue *kq, const struct filter *src)
{
    struct filter *dst;
    unsigned int filt;
    int rv = 0;

    /*
     * This filter is not implemented, see EVFILT_NOTIMPL.
     */
    if (src->kf_id == 0) return (0);

    filt = (-1 * src->kf_id) - 1; /* flip sign, and convert to array offset */
    if (filt >= EVFILT_SYSCOUNT)
        return (-1);

    dst = &kq->kq_filt[filt];
    memcpy(dst, src, sizeof(*src));
    dst->kf_kqueue = kq;
    RB_INIT(&dst->kf_knote);
    pthread_rwlock_init(&dst->kf_knote_mtx, NULL);
    if (src->kf_id == 0) {
        dbg_puts("filter is not implemented");
        return (0);
    }

    assert(src->kf_copyout);
    assert(src->kn_create);
    assert(src->kn_modify);
    assert(src->kn_delete);
    assert(src->kn_enable);
    assert(src->kn_disable);

    /* Perform (optional) per-filter initialization */
    if (src->kf_init != NULL) {
        rv = src->kf_init(dst);
        if (rv < 0) {
            dbg_puts("filter failed to initialize");
            dst->kf_id = 0;
            return (-1);
        }
    }

    /* FIXME: should totally remove const from src */
    if ((kqops.filter_init != NULL) && (kqops.filter_init(kq, dst) < 0))
        return (-1);

    return (0);
}

int
filter_register_all(struct kqueue *kq)
{
    int rv;

    FD_ZERO(&kq->kq_fds);
    rv = 0;
    rv += filter_register(kq, &evfilt_read);
    rv += filter_register(kq, &evfilt_write);
    rv += filter_register(kq, &evfilt_signal);
    rv += filter_register(kq, &evfilt_vnode);
    rv += filter_register(kq, &evfilt_proc);
    rv += filter_register(kq, &evfilt_timer);
    rv += filter_register(kq, &evfilt_user);
    kq->kq_nfds++;
    if (rv != 0) {
        filter_unregister_all(kq);
        return (-1);
    } else {
        dbg_puts("complete");
        return (0);
    }
}

void
filter_unregister_all(struct kqueue *kq)
{
    int i;

    for (i = 0; i < NUM_ELEMENTS(kq->kq_filt); i++) {
        if (kq->kq_filt[i].kf_id == 0)
            continue;

        if (kq->kq_filt[i].kf_destroy != NULL)
            kq->kq_filt[i].kf_destroy(&kq->kq_filt[i]);

        knote_delete_all(&kq->kq_filt[i]);

        if (kqops.filter_free != NULL)
            kqops.filter_free(kq, &kq->kq_filt[i]);
    }
    memset(&kq->kq_filt[0], 0, sizeof(kq->kq_filt));
}

/** Lookup filters in the array of filters registered for kq
 *
 * @param[out] filt    the specified ID resolves to.
 * @param[in] kq       to lookup the filter in.
 * @param[in] id       of the filter to lookup.
 * @return
 *    - 0 on success.
 *    - -1 on failure (filter not implemented).
 */
int
filter_lookup(struct filter **filt, struct kqueue *kq, short id)
{
    if (~id < 0 || ~id >= EVFILT_SYSCOUNT) {
        dbg_printf("invalid id: id %d ~id %d", id, (~id));
        errno = EINVAL;
        *filt = NULL;
        return (-1);
    }
    *filt = &kq->kq_filt[~id];
    if ((*filt)->kf_copyout == NULL) {
        dbg_printf("filter %s is not implemented", filter_name(id));
        errno = ENOSYS;
        *filt = NULL;
        return (-1);
    }

    return (0);
}

const char *
filter_name(short filt)
{
    int id;
    const char *fname[EVFILT_SYSCOUNT] = {
        "EVFILT_READ",
        "EVFILT_WRITE",
        "EVFILT_AIO",
        "EVFILT_VNODE",
        "EVFILT_PROC",
        "EVFILT_SIGNAL",
        "EVFILT_TIMER",
        "EVFILT_NETDEV",
        "EVFILT_FS",
        "EVFILT_LIO",
        "EVFILT_USER"
    };

    id = ~filt;
    if (id < 0 || id >= NUM_ELEMENTS(fname))
        return "EVFILT_INVALID";
    else
        return fname[id];
}
