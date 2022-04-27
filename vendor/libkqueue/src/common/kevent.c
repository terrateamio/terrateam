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

/* To get asprintf(3) */
#define _GNU_SOURCE

#include <assert.h>
#include <signal.h>

#include "private.h"

static struct kevent null_kev[1]; /* null kevent for when we get passed a NULL eventlist */

static const char *
kevent_filter_dump(const struct kevent *kev)
{
    static __thread char buf[64];

    snprintf(buf, sizeof(buf), "%d (%s)",
            kev->filter, filter_name(kev->filter));
    return ((const char *) buf);
}

static const char *
kevent_fflags_dump(const struct kevent *kev)
{
    static __thread char buf[1024];
    size_t len;

#define KEVFFL_DUMP(attrib) \
    if (kev->fflags & attrib) \
    strncat((char *) buf, #attrib" ", 64);

    snprintf(buf, sizeof(buf), "fflags=0x%04x (", kev->fflags);
    switch (kev->filter) {
    case EVFILT_VNODE:
        KEVFFL_DUMP(NOTE_DELETE);
        KEVFFL_DUMP(NOTE_WRITE);
        KEVFFL_DUMP(NOTE_EXTEND);
        KEVFFL_DUMP(NOTE_ATTRIB);
        KEVFFL_DUMP(NOTE_LINK);
        KEVFFL_DUMP(NOTE_RENAME);
        break;

    case EVFILT_USER:
        KEVFFL_DUMP(NOTE_FFNOP);
        KEVFFL_DUMP(NOTE_FFAND);
        KEVFFL_DUMP(NOTE_FFOR);
        KEVFFL_DUMP(NOTE_FFCOPY);
        KEVFFL_DUMP(NOTE_TRIGGER);
        break;

    case EVFILT_READ:
    case EVFILT_WRITE:
#ifdef NOTE_LOWAT
        KEVFFL_DUMP(NOTE_LOWAT);
#endif
        break;

    case EVFILT_PROC:
        KEVFFL_DUMP(NOTE_EXIT);
        KEVFFL_DUMP(NOTE_FORK);
        KEVFFL_DUMP(NOTE_EXEC);
        break;

    case EVFILT_TIMER:
        KEVFFL_DUMP(NOTE_SECONDS);
        KEVFFL_DUMP(NOTE_USECONDS);
        KEVFFL_DUMP(NOTE_NSECONDS);
        KEVFFL_DUMP(NOTE_ABSOLUTE);
        break;

    case EVFILT_LIBKQUEUE:
        KEVFFL_DUMP(NOTE_VERSION);
        KEVFFL_DUMP(NOTE_VERSION_STR);
        KEVFFL_DUMP(NOTE_THREAD_SAFE);
        KEVFFL_DUMP(NOTE_FORK_CLEANUP);
#ifndef NDEBUG
        KEVFFL_DUMP(NOTE_DEBUG);
        KEVFFL_DUMP(NOTE_DEBUG_PREFIX);
        KEVFFL_DUMP(NOTE_DEBUG_FUNC);
#endif
        break;

    default:
        break;
    }
    len = strlen(buf);
    if (buf[len - 1] == ' ') buf[len - 1] = '\0';    /* Trim trailing space */
    strcat(buf, ")");

#undef KEVFFL_DUMP

    return ((const char *) buf);
}

static const char *
kevent_flags_dump(const struct kevent *kev)
{
    static __thread char buf[1024];
    size_t len;

#define KEVFL_DUMP(attrib) \
    if (kev->flags & attrib) \
    strncat((char *) buf, #attrib" ", 64);

    snprintf(buf, sizeof(buf), "flags=0x%04x (", kev->flags);
    KEVFL_DUMP(EV_ADD);
    KEVFL_DUMP(EV_ENABLE);
    KEVFL_DUMP(EV_DISABLE);
    KEVFL_DUMP(EV_DELETE);
    KEVFL_DUMP(EV_ONESHOT);
    KEVFL_DUMP(EV_CLEAR);
    KEVFL_DUMP(EV_EOF);
    KEVFL_DUMP(EV_ERROR);
    KEVFL_DUMP(EV_DISPATCH);
    KEVFL_DUMP(EV_RECEIPT);

    len = strlen(buf);
    if (buf[len - 1] == ' ') buf[len - 1] = '\0';    /* Trim trailing space */
    strcat(buf, ")");

#undef KEVFL_DUMP

    return ((const char *) buf);
}

const char *
kevent_dump(const struct kevent *kev)
{
    static __thread char buf[2147];

    snprintf((char *) buf, sizeof(buf),
            "{ ident=%i, filter=%s, %s, %s, data=%d, udata=%p }",
            (u_int) kev->ident,
            kevent_filter_dump(kev),
            kevent_flags_dump(kev),
            kevent_fflags_dump(kev),
            (int) kev->data,
            kev->udata);

    return ((const char *) buf);
}

/** Process a single entry in the changelist
 *
 * @param[out] out    The knote the src kevent resolved to (if any).
 * @param[in] kq      to apply the change against.
 * @param[in] src     the change being applied.
 * @return
 *     - 1 on success.  Caller should add a receipt entry based on the kev
 *       contained within the knote.  This is used for the EVFILT_LIBKQUEUE
 *       to support its use as a query interface.
 *     - 0 on success.  Caller should add a receipt entry if EV_RECEIPT was
 *       set in the src kevent.
 *     - -1 on failure.  Caller should add a receipt entry containing the error.
 *       in the data field.
 */
static int
kevent_copyin_one(const struct knote **out, struct kqueue *kq, const struct kevent *src)
{
    struct knote  *kn = NULL;
    struct filter *filt;
    int rv = 0;

    if (src->flags & EV_DISPATCH && src->flags & EV_ONESHOT) {
        dbg_puts("Error: EV_DISPATCH and EV_ONESHOT are mutually exclusive");
        errno = EINVAL;
        return (-1);
    }

    if (filter_lookup(&filt, kq, src->filter) < 0)
        return (-1);

    dbg_printf("src=%s", kevent_dump(src));

    kn = knote_lookup(filt, src->ident);
    if (kn == NULL) {
        if (src->flags & EV_ADD) {
            if ((kn = knote_new()) == NULL) {
                errno = ENOENT;
                *out = NULL;
                return (-1);
            }
            memcpy(&kn->kev, src, sizeof(kn->kev));
            kn->kev.flags &= ~EV_ENABLE;
            kn->kn_kq = kq;
            assert(filt->kn_create);
            rv = filt->kn_create(filt, kn);
            if (rv < 0) {
                dbg_puts("kn_create failed");

                kn->kn_flags |= KNFL_KNOTE_DELETED;
                knote_release(kn);

                errno = EFAULT;
                *out = NULL;
                return (-1);
            }
            knote_insert(filt, kn);
            dbg_printf("kn=%p - created knote %s", kn, kevent_dump(src));
            *out = kn;

/* XXX- FIXME Needs to be handled in kn_create() to prevent races */
            if (src->flags & EV_DISABLE) {
                kn->kev.flags |= EV_DISABLE;
                return filt->kn_disable(filt, kn);
            }
            //........................................
            return (rv);
        } else {
            dbg_printf("ident=%u - no knote found", (unsigned int)src->ident);
            errno = ENOENT;
            *out = NULL;
            return (-1);
        }
    } else {
        dbg_printf("kn=%p - resolved ident=%i to knote", kn, (int)src->ident);
    }

    if (src->flags & EV_DELETE) {
        rv = knote_delete(filt, kn);
    } else if (src->flags & EV_DISABLE) {
        rv = knote_disable(filt, kn);
    } else if (src->flags & EV_ENABLE) {
        rv = knote_enable(filt, kn);
    } else if (src->flags & EV_ADD || src->flags == 0 || src->flags & EV_RECEIPT) {
        rv = filt->kn_modify(filt, kn, src);
        /*
         * Implement changes common to all filters
         */
        if (rv == 0) {
            /* update udata */
            kn->kev.udata = src->udata;

            /* sync up the dispatch bit */
            COPY_FLAGS_BIT(kn->kev, (*src), EV_DISPATCH);
        }
        dbg_printf("kn=%p - kn_modify rv=%d", kn, rv);
    }
    *out = kn;

    return (rv);
}

/** @return number of events added to the eventlist */
static int
kevent_copyin(struct kqueue *kq, const struct kevent changelist[], int nchanges,
        struct kevent eventlist[], int nevents)
{
    int status;
    int rv;
    struct kevent *el_p = eventlist, *el_end = el_p + nevents;

    dbg_printf("nchanges=%d nevents=%d", nchanges, nevents);


#define CHECK_EVENTLIST_SPACE \
    do { \
        if (el_p == el_end) { \
            if (errno == 0) errno = EFAULT; \
            return (-1); \
        } \
    } while (0)

    for (struct kevent const *cl_p = changelist, *cl_end = cl_p + nchanges;
         cl_p < cl_end;
         cl_p++) {
        const struct knote *kn;

        rv = kevent_copyin_one(&kn, kq, cl_p);
        if (rv == 1) {
            if (el_p == el_end) {
                errno = EFAULT;
                return (-1);
            }
            memcpy(el_p, &kn->kev, sizeof(*el_p));
            el_p->flags |= EV_RECEIPT;
            el_p++;

        } else if (rv < 0) {
            dbg_printf("errno=%s", strerror(errno));
            /*
             * We're out of kevent entries, just return -1 and leave
             * the errno set.  This is... odd, because it means the
             * caller won't have any idea which entries in the
             * changelist were processed.  But I guess the
             * requirement here is for the caller to always provide
             * a kevent array with >= entries as the changelist.
             */
            if (el_p == el_end)
                return (-1);
            status = errno;
            errno = 0; /* Reset back to 0 if we recorded the error as a kevent */

        receipt:
            memcpy(el_p, cl_p, sizeof(*el_p));
            el_p->flags |= EV_ERROR; /* This is set both on error and for EV_RECEIPT */
            el_p->data = status;
            el_p++;

        /*
         * This allows our custom filter to create eventlist
         * entries in response to queries.
         */
        } else if (cl_p->flags & EV_RECEIPT) {
            status = 0;
            if (el_p == el_end) {
                errno = EFAULT;
                return (-1);
            }
            goto receipt;
        }
    }

    return (el_p - eventlist);
}

#ifndef _WIN32
static void
kevent_release_kq_mutex(void *kq)
{
    kqueue_unlock((struct kqueue *)kq);
}
#endif

int VISIBLE
kevent(int kqfd,
       const struct kevent changelist[], int nchanges,
       struct kevent eventlist[], int nevents,
       const struct timespec *timeout)
{
    struct kqueue *kq;
    struct kevent *el_p, *el_end;
    int rv = 0;
#ifndef _WIN32
    int prev_cancel_state;
#endif
#ifndef NDEBUG
    static atomic_uint _kevent_counter = 0;
    unsigned int myid = 0;
    (void) myid;
#endif
    /* deal with ubsan "runtime error: applying zero offset to null pointer" */
    if (eventlist) {
        if (nevents > MAX_KEVENT)
            nevents = MAX_KEVENT;

        el_p = eventlist;
        el_end = el_p + nevents;
    } else {
        eventlist = el_p = el_end = null_kev;
    }
    if (!changelist) changelist = null_kev;

#ifndef _WIN32
    prev_cancel_state = pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, NULL);
#endif
    /*
     * Grab the global mutex.  This prevents
     * any operations that might free the
     * kqueue from progressing.
     */
    if (libkqueue_thread_safe)
        tracing_mutex_lock(&kq_mtx);

    /* Convert the descriptor into an object pointer */
    kq = kqueue_lookup(kqfd);
    if (kq == NULL) {
        errno = ENOENT;
        if (libkqueue_thread_safe)
            tracing_mutex_unlock(&kq_mtx);
#ifndef _WIN32
        pthread_setcancelstate(prev_cancel_state, NULL);
#endif
        return (-1);
    }

    kqueue_lock(kq);

#ifndef _WIN32
    pthread_cleanup_push(kevent_release_kq_mutex, kq);
#endif

    /*
     * We no longer need the global mutex as
     * nothing else can use this kqueue until
     * we release the lock.
     */
    if (libkqueue_thread_safe)
        tracing_mutex_unlock(&kq_mtx);
#ifndef NDEBUG
    if (libkqueue_debug) {
        myid = atomic_inc(&_kevent_counter);
        dbg_printf("--- START kevent %u --- (nchanges = %d nevents = %d)", myid, nchanges, nevents);
    }
#endif

    /*
     * Process each kevent on the changelist.
     */
    if (nchanges > 0) {
        /*
         * Grab the kqueue specific mutex, this
         * prevents any operations on the specific
         * kqueue from progressing.
         */
        rv = kevent_copyin(kq, changelist, nchanges, el_p, el_end - el_p);
        dbg_printf("(%u) kevent_copyin rv=%d", myid, rv);
        if (rv < 0)
            goto out;
        if (rv > 0) {
            el_p += rv; /* EV_RECEIPT and EV_ERROR entries */
        }
    }

    /*
     * If we have space remaining after processing
     * the changelist, copy events out.
     */
    if ((el_end - el_p) > 0) {
        /*
         * Allow cancellation in kevent_wait as we
         * may be waiting a long time for the thread
         * to exit...
         */
#ifndef _WIN32
        (void)pthread_setcancelstate(prev_cancel_state, NULL);
        if (prev_cancel_state == PTHREAD_CANCEL_ENABLE)
            pthread_testcancel();
#endif
        rv = kqops.kevent_wait(kq, nevents, timeout);
#ifndef _WIN32
        (void)pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, NULL);
#endif
        dbg_printf("kqops.kevent_wait rv=%i", rv);
        if (likely(rv > 0)) {
            rv = kqops.kevent_copyout(kq, rv, el_p, el_end - el_p);
            dbg_printf("(%u) kevent_copyout rv=%i", myid, rv);
            if (rv >= 0) {
                el_p += rv;             /* Add events from copyin */
                rv = el_p - eventlist;  /* recalculate rv to be the total events in the eventlist */
            }
        } else if (rv == 0) {
            /* Timeout reached */
            dbg_printf("(%u) kevent_wait timedout", myid);
        } else {
            dbg_printf("(%u) kevent_wait failed", myid);
            goto out;
        }
    /*
     * If we have no space, return how many kevents
     * were added by copyin.
     */
    } else {
        rv = el_p - eventlist;
    }

#ifndef NDEBUG
    if (libkqueue_debug && (rv > 0)) {
        int n;

        dbg_printf("(%u) returning %zu events", myid, el_p - eventlist);
        for (n = 0; n < el_p - eventlist; n++) {
            dbg_printf("(%u) eventlist[%d] = %s", myid, n, kevent_dump(&eventlist[n]));
        }
    }
#endif

out:
#ifndef _WIN32
    pthread_cleanup_pop(0);
#endif
    kqueue_unlock(kq);
    dbg_printf("--- END kevent %u ret %d ---", myid, rv);

#ifndef _WIN32
    pthread_setcancelstate(prev_cancel_state, NULL);
    if (prev_cancel_state == PTHREAD_CANCEL_ENABLE)
        pthread_testcancel();
#endif

    return (rv);
}
