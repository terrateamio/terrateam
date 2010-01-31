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

static int __thread kqfd;

void
test_kevent_timer_add(void)
{
    struct kevent kev;

    EV_SET(&kev, 1, EVFILT_TIMER, EV_ADD, 0, 1000, NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);
}

void
test_kevent_timer_del(void)
{
    struct kevent kev;

    EV_SET(&kev, 1, EVFILT_TIMER, EV_DELETE, 0, 0, NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    test_no_kevents(kqfd);
}

void
test_kevent_timer_get(void)
{
    struct kevent kev;

    EV_SET(&kev, 1, EVFILT_TIMER, EV_ADD, 0, 1000, NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    kev.flags |= EV_CLEAR;
    kev.data = 1; 
    kevent_cmp(&kev, kevent_get(kqfd));

    EV_SET(&kev, 1, EVFILT_TIMER, EV_DELETE, 0, 0, NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);
}

static void
test_kevent_timer_oneshot(void)
{
    struct kevent kev;

    test_no_kevents(kqfd);

    EV_SET(&kev, 2, EVFILT_TIMER, EV_ADD | EV_ONESHOT, 0, 500,NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    /* Retrieve the event */
    kev.flags = EV_ADD | EV_CLEAR | EV_ONESHOT;
    kev.data = 1; 
    kevent_cmp(&kev, kevent_get(kqfd));

    /* Check if the event occurs again */
    sleep(3);
    test_no_kevents(kqfd);
}

static void
test_kevent_timer_periodic(void)
{
    struct kevent kev;

    test_no_kevents(kqfd);

    EV_SET(&kev, 3, EVFILT_TIMER, EV_ADD, 0, 1000,NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    /* Retrieve the event */
    kev.flags = EV_ADD | EV_CLEAR;
    kev.data = 1; 
    kevent_cmp(&kev, kevent_get(kqfd));

    /* Check if the event occurs again */
    sleep(1);
    kevent_cmp(&kev, kevent_get(kqfd));

    /* Delete the event */
    kev.flags = EV_DELETE;
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);
}

static void
test_kevent_timer_disable_and_enable(void)
{
    struct kevent kev;

    test_no_kevents(kqfd);

    /* Add the watch and immediately disable it */
    EV_SET(&kev, 4, EVFILT_TIMER, EV_ADD | EV_ONESHOT, 0, 2000,NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);
    kev.flags = EV_DISABLE;
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);
    test_no_kevents(kqfd);

    /* Re-enable and check again */
    kev.flags = EV_ENABLE;
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    kev.flags = EV_ADD | EV_CLEAR | EV_ONESHOT;
    kev.data = 1; 
    kevent_cmp(&kev, kevent_get(kqfd));
}

void
test_evfilt_timer(int _kqfd)
{
	kqfd = _kqfd;
    test(kevent_timer_add);
    test(kevent_timer_del);
    test(kevent_timer_get);
    test(kevent_timer_oneshot);
    test(kevent_timer_periodic);
    test(kevent_timer_disable_and_enable);
}
