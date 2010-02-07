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
test_kevent_signal_add(void)
{
    struct kevent kev;

    kevent_add(kqfd, &kev, SIGUSR1, EVFILT_SIGNAL, EV_ADD, 0, 0, NULL);
}

void
test_kevent_signal_get(void)
{
    struct kevent kev;

    kevent_add(kqfd, &kev, SIGUSR1, EVFILT_SIGNAL, EV_ADD, 0, 0, NULL);    

    /* Block SIGUSR1, then send it to ourselves */
    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, SIGUSR1);
    if (sigprocmask(SIG_BLOCK, &mask, NULL) == -1)
        die("sigprocmask");
    if (kill(getpid(), SIGUSR1) < 0)
        die("kill");

    kev.flags |= EV_CLEAR;
    kev.data = 1;
    kevent_cmp(&kev, kevent_get(kqfd));
}

void
test_kevent_signal_disable(void)
{
    struct kevent kev;

    kevent_add(kqfd, &kev, SIGUSR1, EVFILT_SIGNAL, EV_DISABLE, 0, 0, NULL);

    /* Block SIGUSR1, then send it to ourselves */
    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, SIGUSR1);
    if (sigprocmask(SIG_BLOCK, &mask, NULL) == -1)
        die("sigprocmask");
    if (kill(getpid(), SIGUSR1) < 0)
        die("kill");

    test_no_kevents(kqfd);
}

void
test_kevent_signal_enable(void)
{
    struct kevent kev;

    kevent_add(kqfd, &kev, SIGUSR1, EVFILT_SIGNAL, EV_ENABLE, 0, 0, NULL);

    /* Block SIGUSR1, then send it to ourselves */
    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, SIGUSR1);
    if (sigprocmask(SIG_BLOCK, &mask, NULL) == -1)
        die("sigprocmask");
    if (kill(getpid(), SIGUSR1) < 0)
        die("kill");

    kev.flags = EV_ADD | EV_CLEAR;
#if LIBKQUEUE
    kev.data = 1; /* WORKAROUND */
#else
    kev.data = 2; // one extra time from test_kevent_signal_disable()
#endif
    kevent_cmp(&kev, kevent_get(kqfd));

    /* Delete the watch */
    kev.flags = EV_DELETE;
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        die("kevent");
}

void
test_kevent_signal_del(void)
{
    struct kevent kev;

    /* Delete the kevent */
    kevent_add(kqfd, &kev, SIGUSR1, EVFILT_SIGNAL, EV_DELETE, 0, 0, NULL);

    /* Block SIGUSR1, then send it to ourselves */
    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, SIGUSR1);
    if (sigprocmask(SIG_BLOCK, &mask, NULL) == -1)
        die("sigprocmask");
    if (kill(getpid(), SIGUSR1) < 0)
        die("kill");

    test_no_kevents(kqfd);
}

void
test_kevent_signal_oneshot(void)
{
    struct kevent kev;

    kevent_add(kqfd, &kev, SIGUSR1, EVFILT_SIGNAL, EV_ADD | EV_ONESHOT, 0, 0, NULL);

    /* Block SIGUSR1, then send it to ourselves */
    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, SIGUSR1);
    if (sigprocmask(SIG_BLOCK, &mask, NULL) == -1)
        die("sigprocmask");
    if (kill(getpid(), SIGUSR1) < 0)
        die("kill");

    kev.flags |= EV_CLEAR;
    kev.data = 1;
    kevent_cmp(&kev, kevent_get(kqfd));

    /* Send another one and make sure we get no events */
    if (kill(getpid(), SIGUSR1) < 0)
        die("kill");
    test_no_kevents(kqfd);
}

void
test_evfilt_signal(int _kqfd)
{
	kqfd = _kqfd;
    test(kevent_signal_add);
    test(kevent_signal_del);
    test(kevent_signal_get);
    test(kevent_signal_disable);
    test(kevent_signal_enable);
    test(kevent_signal_oneshot);
}
