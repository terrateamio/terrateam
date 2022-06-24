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
#include "common.h"

#ifdef EVFILT_LIBKQUEUE
static void
test_libkqueue_version(struct test_context *ctx)
{
    struct kevent kev, receipt;

    EV_SET(&kev, 0, EVFILT_LIBKQUEUE, EV_ADD, NOTE_VERSION, 0, NULL);
    if (kevent(ctx->kqfd, &kev, 1, &receipt, 1, &(struct timespec){}) != 1) {
        printf("Unable to add the following kevent:\n%s\n",
               kevent_to_str(&kev));
        die("kevent");
    }

    if (receipt.data == 0) {
        printf("No version number returned");
        die("kevent");
    }
}

static void
test_libkqueue_version_str(struct test_context *ctx)
{
    struct kevent kev, receipt;

    EV_SET(&kev, 0, EVFILT_LIBKQUEUE, EV_ADD, NOTE_VERSION_STR, 0, NULL);
    if (kevent(ctx->kqfd, &kev, 1, &receipt, 1, &(struct timespec){}) != 1) {
        printf("Unable to add the following kevent:\n%s\n",
               kevent_to_str(&kev));
        die("kevent");
    }

    if (!strlen((char *)receipt.udata)) {
        printf("empty version number returned");
        die("kevent");
    }
}

void
test_evfilt_libkqueue(struct test_context *ctx)
{
    test(libkqueue_version, ctx);
    test(libkqueue_version_str, ctx);
}
#endif
