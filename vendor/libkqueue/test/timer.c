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

void
test_kevent_timer_add(struct test_context *ctx)
{
    struct kevent kev;

    kevent_add(ctx->kqfd, &kev, 1, EVFILT_TIMER, EV_ADD, 0, 1000, NULL);
}

void
test_kevent_timer_del(struct test_context *ctx)
{
    struct kevent kev;

    kevent_add(ctx->kqfd, &kev, 1, EVFILT_TIMER, EV_DELETE, 0, 0, NULL);

    test_no_kevents(ctx->kqfd);
}

void
test_kevent_timer_get(struct test_context *ctx)
{
    struct kevent kev, ret[1];

    kevent_add(ctx->kqfd, &kev, 1, EVFILT_TIMER, EV_ADD, 0, 1000, NULL);

    kev.flags |= EV_CLEAR;
    kev.data = 1;
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);

    kevent_add(ctx->kqfd, &kev, 1, EVFILT_TIMER, EV_DELETE, 0, 0, NULL);
}

static void
test_kevent_timer_oneshot(struct test_context *ctx)
{
    struct kevent kev, ret[1];

    test_no_kevents(ctx->kqfd);

    kevent_add(ctx->kqfd, &kev, 2, EVFILT_TIMER, EV_ADD | EV_ONESHOT, 0, 500, NULL);

    /* Retrieve the event */
    kev.flags = EV_ADD | EV_CLEAR | EV_ONESHOT;
    kev.data = 1;
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);

    /* Check if the event occurs again */
    sleep(3);
    test_no_kevents(ctx->kqfd);
}

static void
test_kevent_timer_periodic(struct test_context *ctx)
{
    struct kevent kev, ret[1];

    test_no_kevents(ctx->kqfd);

    kevent_add(ctx->kqfd, &kev, 3, EVFILT_TIMER, EV_ADD, 0, 1000, NULL);

    /* Retrieve the event */
    kev.flags = EV_ADD | EV_CLEAR;
    kev.data = 1;
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);

    /* Check if the event occurs again */
    sleep(1);
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);

    /* Delete the event */
    kev.flags = EV_DELETE;
    kevent_update(ctx->kqfd, &kev);
}

static void
test_kevent_timer_periodic_modify(struct test_context *ctx)
{
    struct kevent kev, ret[1];

    test_no_kevents(ctx->kqfd);

    kevent_add(ctx->kqfd, &kev, 3, EVFILT_TIMER, EV_ADD, 0, 1000, NULL);

    /* Retrieve the event */
    kev.flags = EV_ADD | EV_CLEAR;
    kev.data = 1;
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);

    /* Check if the event occurs again */
    kevent_add(ctx->kqfd, &kev, 3, EVFILT_TIMER, EV_ADD, 0, 500, NULL);
    kev.flags = EV_ADD | EV_CLEAR;
    sleep(1);
    kev.data = 2;	/* Should have fired twice */

    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);

    /* Delete the event */
    kev.flags = EV_DELETE;
    kevent_update(ctx->kqfd, &kev);
}

/*
 * This appears to be a bug in the Linux/FreeBSD implementation where
 * it won't allow you to modify an existing event to make it oneshot.
 */
#if WITH_NATIVE_KQUEUE_BUGS
static void
test_kevent_timer_periodic_to_oneshot(struct test_context *ctx)
{
    struct kevent kev, ret[1];

    test_no_kevents(ctx->kqfd);

    kevent_add(ctx->kqfd, &kev, 3, EVFILT_TIMER, EV_ADD, 0, 1000, NULL);

    /* Retrieve the event */
    kev.flags = EV_ADD | EV_CLEAR;
    kev.data = 1;
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);

    /* Check if the event occurs again */
    sleep(1);
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);

    /* Switch to oneshot */
    kevent_add(ctx->kqfd, &kev, 3, EVFILT_TIMER, EV_ADD | EV_ONESHOT, 0, 500, NULL);
    kev.flags = EV_ADD | EV_CLEAR;

    sleep(1);
    kev.data = 1;	/* Should have fired one */

    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);

    /* Delete the event */
    kev.flags = EV_DELETE;
    kevent_update_expect_fail(ctx->kqfd, &kev);
}
#endif

static void
test_kevent_timer_disable_and_enable(struct test_context *ctx)
{
    struct kevent kev, ret[1];

    test_no_kevents(ctx->kqfd);

    /* Add the watch and immediately disable it */
    kevent_add(ctx->kqfd, &kev, 4, EVFILT_TIMER, EV_ADD | EV_ONESHOT, 0, 2000,NULL);
    kev.flags = EV_DISABLE;
    kevent_update(ctx->kqfd, &kev);
    test_no_kevents(ctx->kqfd);

    /* Re-enable and check again */
    kev.flags = EV_ENABLE;
    kevent_update(ctx->kqfd, &kev);

    kev.flags = EV_ADD | EV_CLEAR | EV_ONESHOT;
    kev.data = 1;
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);
}

#ifdef EV_DISPATCH
void
test_kevent_timer_dispatch(struct test_context *ctx)
{
    struct kevent kev, ret[1];

    test_no_kevents(ctx->kqfd);

    kevent_add(ctx->kqfd, &kev, 4, EVFILT_TIMER, EV_ADD | EV_DISPATCH, 0, 200, NULL);

    /* Get one event */
    kev.flags = EV_ADD | EV_CLEAR | EV_DISPATCH;
    kev.data = 1;
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);

    /* Confirm that the knote is disabled due to EV_DISPATCH */
    usleep(500000); /* 500 ms */
    test_no_kevents(ctx->kqfd);

#if WITH_NATIVE_KQUEUE_BUGS || !defined(__FreeBSD__)
    /*
     * macOS and FreeBSD both share the same bug.
     *
     * When a timer event with EV_DISPATCH is re-enabled
     * although the EV_DISPATCH flag is high in the
     * returned event the timer filter behaves as if
     * EV_DISPATCH it's not set and will fire multiple
     * times.
     */

    /* Enable the knote and make sure no events are pending */
    kevent_add(ctx->kqfd, &kev, 4, EVFILT_TIMER, EV_ENABLE | EV_DISPATCH, 0, 200, NULL);
    test_no_kevents(ctx->kqfd);

    /* Get the next event */
    usleep(1100000); /* 1100 ms */
    kev.flags = EV_ADD | EV_CLEAR | EV_DISPATCH;
    kev.data = 5;
    kevent_get(ret, NUM_ELEMENTS(ret), ctx->kqfd, 1);
    kevent_cmp(&kev, ret);
#endif

    /* Remove the knote and ensure the event no longer fires */
    kevent_add(ctx->kqfd, &kev, 4, EVFILT_TIMER, EV_DELETE, 0, 0, NULL);
    usleep(500000); /* 500 ms */
    test_no_kevents(ctx->kqfd);
}
#endif  /* EV_DISPATCH */

void
test_evfilt_timer(struct test_context *ctx)
{
    test(kevent_timer_add, ctx);
    test(kevent_timer_del, ctx);
    test(kevent_timer_get, ctx);
    test(kevent_timer_oneshot, ctx);
    test(kevent_timer_periodic, ctx);
    test(kevent_timer_periodic_modify, ctx);
#if WITH_NATIVE_KQUEUE_BUGS
    test(kevent_timer_periodic_to_oneshot, ctx);
#endif
    test(kevent_timer_disable_and_enable, ctx);
#ifdef EV_DISPATCH
    test(kevent_timer_dispatch, ctx);
#endif
}
