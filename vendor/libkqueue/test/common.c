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

#include "common.h"

extern int kqfd;

/* Checks if any events are pending, which is an error. */
void
_test_no_kevents(int kqfd, const char *file, int line)
{
    int nfds;
    struct timespec timeo;
    struct kevent kev;

    memset(&timeo, 0, sizeof(timeo));
    nfds = kevent(kqfd, NULL, 0, &kev, 1, &timeo);
    if (nfds < 0)
        err(1, "kevent(2)");
    if (nfds > 0) {
        printf("\n[%s:%d]: Unexpected event:", file, line);
        err(1, "%s", kevent_to_str(&kev));
    }
}

/* Retrieve a single kevent */
void
kevent_get(struct kevent kev[], int numevents, int kqfd, int expect)
{
    struct kevent buf;
    int nfds;

    if (kev == NULL) {
       kev = &buf;
       numevents = 1;
    }

    kevent_rv_cmp(expect, kevent(kqfd, NULL, 0, kev, numevents, NULL));
}

/**
 * Retrieve a single kevent, specifying a maximum time to wait for it.
 * Result:
 * 0 = Timeout
 * 1 = Success
 */
int
kevent_get_timeout(struct kevent kev[], int numevents, int fd, struct timespec *ts)
{
    int nfds;

    nfds = kevent(fd, NULL, 0, kev, numevents, ts);
    if (nfds < 0) {
        err(1, "kevent(2)");
    } else if (nfds == 0) {
        return 0;
    }

    return 1;
}

/* In Linux, a kevent() call with less than 1ms resolution
   will perform a pselect() call to obtain the higer resolution.
   This test exercises that codepath.
 */
void
kevent_get_hires(struct kevent kev[], int numevents, int kqfd, struct timespec *ts)
{
    int nfds;

    nfds = kevent(kqfd, NULL, 0, kev, numevents, ts);
    if (nfds < 1)
        die("kevent(2)");
}

static const char *
filter_name(short filt)
{
    int id;
    const char *fname[EVFILT_SYSCOUNT] = {
        [~EVFILT_READ] = "EVFILT_READ",
        [~EVFILT_WRITE] = "EVFILT_WRITE",
        [~EVFILT_AIO] = "EVFILT_AIO",
        [~EVFILT_VNODE] = "EVFILT_VNODE",
        [~EVFILT_PROC] = "EVFILT_PROC",
        [~EVFILT_SIGNAL] = "EVFILT_SIGNAL",
        [~EVFILT_TIMER] = "EVFILT_TIMER",
#ifdef EVFILT_NETDEV
        [~EVFILT_NETDEV] = "EVFILT_NETDEV",
#endif
        [~EVFILT_FS] = "EVFILT_FS",
#ifdef EVFILT_LIO
        [~EVFILT_LIO] = "EVFILT_LIO",
#endif
        [~EVFILT_USER] = "EVFILT_USER",

#ifdef EVFILT_LIBKQUEUE
        [~EVFILT_LIBKQUEUE] = "EVFILT_LIBKQUEUE"
#endif
    };

    id = ~filt;
    if (id < 0 || id >= NUM_ELEMENTS(fname))
        return "EVFILT_INVALID";
    else
        return fname[id];
}

static const char *
kevent_filter_dump(const struct kevent *kev)
{
    static __thread char buf[64];

    snprintf(buf, sizeof(buf), "%d (%s)",
            kev->filter, filter_name(kev->filter));
    return ((const char *) buf);
}

char *
kevent_fflags_dump(struct kevent *kev)
{
    static __thread char buf[512];
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
        KEVFFL_DUMP(NOTE_CHILD);
        KEVFFL_DUMP(NOTE_EXIT);
#ifdef NOTE_EXITSTATUS
        KEVFFL_DUMP(NOTE_EXITSTATUS);
#endif
        KEVFFL_DUMP(NOTE_FORK);
        KEVFFL_DUMP(NOTE_EXEC);
#ifdef NOTE_SIGNAL
        KEVFFL_DUMP(NOTE_SIGNAL);
#endif
        break;

#ifdef EVFILT_LIBKQUEUE
    case EVFILT_LIBKQUEUE:
        KEVFFL_DUMP(NOTE_VERSION);
        KEVFFL_DUMP(NOTE_VERSION_STR);
        break;
#endif

    default:
        break;
    }
    len = strlen(buf);
    if (buf[len - 1] == ' ') buf[len - 1] = '\0';    /* Trim trailing space */
    strcat(buf, ")");

#undef KEVFFL_DUMP

    return (buf);
}

char *
kevent_flags_dump(struct kevent *kev)
{
    static __thread char buf[512];

#define KEVFL_DUMP(attrib) \
    if (kev->flags & attrib) \
    strncat(buf, #attrib" ", 64);

    snprintf(buf, sizeof(buf), "flags = %d (", kev->flags);
    KEVFL_DUMP(EV_ADD);
    KEVFL_DUMP(EV_ENABLE);
    KEVFL_DUMP(EV_DISABLE);
    KEVFL_DUMP(EV_DELETE);
    KEVFL_DUMP(EV_ONESHOT);
    KEVFL_DUMP(EV_CLEAR);
    KEVFL_DUMP(EV_EOF);
    KEVFL_DUMP(EV_ERROR);
#ifdef EV_DISPATCH
    KEVFL_DUMP(EV_DISPATCH);
#endif
#ifdef EV_RECEIPT
    KEVFL_DUMP(EV_RECEIPT);
#endif
    buf[strlen(buf) - 1] = ')';

    return (buf);
}

/* TODO - backport changes from src/common/kevent.c kevent_dump() */
const char *
kevent_to_str(struct kevent *kev)
{
    static __thread char buf[512];

    snprintf(buf, sizeof(buf),
            "[ident=%d, filter=%s, %s, %s, data=%d, udata=%p]",
            (u_int) kev->ident,
            kevent_filter_dump(kev),
            kevent_flags_dump(kev),
            kevent_fflags_dump(kev),
            (int) kev->data,
            kev->udata);

    return buf;
}

void
kevent_update(int kqfd, struct kevent *kev)
{
    if (kevent(kqfd, kev, 1, NULL, 0, NULL) < 0) {
        printf("Unable to add the following kevent:\n%s\n",
                kevent_to_str(kev));
        die("kevent");
    }
}

void
kevent_update_expect_fail(int kqfd, struct kevent *kev)
{
    if (kevent(kqfd, kev, 1, NULL, 0, NULL) >= 0) {
        printf("Performing update should fail");
        die("kevent");
    }
}

void
kevent_add(int kqfd, struct kevent *kev,
        uintptr_t ident,
        short     filter,
        u_short   flags,
        u_int     fflags,
        intptr_t  data,
        void      *udata)
{
    EV_SET(kev, ident, filter, flags, fflags, data, NULL);
    if (kevent(kqfd, kev, 1, NULL, 0, NULL) < 0) {
        printf("Unable to add the following kevent:\n%s\n",
                kevent_to_str(kev));
        die("kevent");
    }
}

/** Check kqueue echo's the event back to use correctly
 *
 * @param[in] kqfd    we're adding events to.
 * @param[out] kev    the event we got passed back in
 *                    the receipt.
 * @param[in] ident   Identifier for the event.
 * @param[in] filter  to add event to.
 * @param[in] flags   to set.
 * @param[in] fflags  to set.
 * @param[in] data    to set.
 * @param[in] udata   to set.
 * @param[in] file    this function was called from.
 * @param[in] line    this function was called from.
 */
void
_kevent_add_with_receipt(int kqfd, struct kevent *kev,
        uintptr_t ident,
        short     filter,
        u_short   flags,
        u_int     fflags,
        intptr_t  data,
        void      *udata,
        char const *file,
        int       line)
{
    struct kevent receipt;

    EV_SET(kev, ident, filter, flags | EV_RECEIPT, fflags, data, NULL);
    if (kevent(kqfd, kev, 1, &receipt, 1, NULL) < 0) {
        printf("Unable to add the following kevent:\n%s\n",
                kevent_to_str(kev));
        die("kevent");
    }


#ifdef __FreeBSD__
    /*
     * FreeBSD doesn't return EV_RECEIPT in the receipt
     * but does return it in all future kevents.
     */
    kev->flags ^= EV_RECEIPT;
#endif

    kev->flags |= EV_ERROR;
    _kevent_cmp(kev, &receipt, file, line);
    kev->flags ^= EV_ERROR; /* We don't expect this in future events */

#ifdef __FreeBSD__
    /*
     * Add this back as it'll be returned in future
     * kevents.
     */
    kev->flags |= EV_RECEIPT;
#endif
}

void
_kevent_cmp(struct kevent *expected, struct kevent *got, const char *file, int line)
{
/* XXX-
   Workaround for inconsistent implementation of kevent(2)
 */
#if defined (__FreeBSD_kernel__) || defined (__FreeBSD__)
    if (expected->flags & EV_ADD)
        got->flags |= EV_ADD;
#endif
    if (memcmp(expected, got, sizeof(*expected)) != 0) {
        printf("[%s:%d]: kevent_cmp() failed:\n", file, line);
        printf("expected %s\n", kevent_to_str(expected));
        printf("but got  %s\n", kevent_to_str(got));
        abort();
    }
}

void
_kevent_rv_cmp(int expected, int got, const char *file, int line)
{
    if (expected != got) {
        printf("[%s:%d]: kevent_rv_cmp() failed:\n", file, line);
        printf("expected %u\n", expected);
        printf("but got  %u\n", got);
        abort();
    }
}
