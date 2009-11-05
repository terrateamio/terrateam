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

int kqfd;

void
test_kevent_timer_add(void)
{
    const char *test_id = "kevent(EVFILT_TIMER, EV_ADD)";
    struct kevent kev;

    test_begin(test_id);

    EV_SET(&kev, 1, EVFILT_TIMER, EV_ADD, 0, 1000, NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    success(test_id);
}

void
test_kevent_timer_del(void)
{
    const char *test_id = "kevent(EVFILT_TIMER, EV_DELETE)";
    struct kevent kev;

    test_begin(test_id);

    EV_SET(&kev, 1, EVFILT_TIMER, EV_DELETE, 0, 0, NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    success(test_id);
}

void
test_kevent_timer_get(void)
{
    const char *test_id = "kevent(EVFILT_TIMER, get)";
    struct kevent kev;
    int nfds;

    test_begin(test_id);

    EV_SET(&kev, 1, EVFILT_TIMER, EV_ADD, 0, 1000, NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    nfds = kevent(kqfd, NULL, 0, &kev, 1, NULL);
    if (nfds < 1)
        err(1, "%s", test_id);
    if (kev.ident != 1 || kev.filter != EVFILT_TIMER) 
        errx(1, "wrong event");

    EV_SET(&kev, 1, EVFILT_TIMER, EV_DELETE, 0, 0, NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    success(test_id);
}

void
test_evfilt_timer()
{
	kqfd = kqueue();
        test_kevent_timer_add();
        test_kevent_timer_del();
        test_kevent_timer_get();
#if TODO
        test_kevent_signal_disable();
        test_kevent_signal_enable();
        test_kevent_signal_oneshot();
#endif
	close(kqfd);
}
