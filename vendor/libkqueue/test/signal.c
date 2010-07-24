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

    if (kill(getpid(), SIGUSR1) < 0)
        die("kill");

    test_no_kevents(kqfd);
}

void
test_kevent_signal_enable(void)
{
    struct kevent kev;

    kevent_add(kqfd, &kev, SIGUSR1, EVFILT_SIGNAL, EV_ENABLE, 0, 0, NULL);

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

    signal(SIGUSR1, SIG_IGN);
    if (kill(getpid(), SIGUSR1) < 0)
        die("kill");

    test_no_kevents(kqfd);
}

void
test_kevent_signal_oneshot(void)
{
    struct kevent kev;

    kevent_add(kqfd, &kev, SIGUSR1, EVFILT_SIGNAL, EV_ADD | EV_ONESHOT, 0, 0, NULL);

    if (kill(getpid(), SIGUSR1) < 0)
        die("kill");

    kev.flags |= EV_CLEAR;
    kev.data = 1;
    kevent_cmp(&kev, kevent_get(kqfd));

    /* Send another one and make sure we get no events */
    test_no_kevents(kqfd);
    if (kill(getpid(), SIGUSR1) < 0)
        die("kill");
    test_no_kevents(kqfd);
}

void
test_kevent_signal_modify(void)
{
    struct kevent kev;

    kevent_add(kqfd, &kev, SIGUSR1, EVFILT_SIGNAL, EV_ADD, 0, 0, NULL);
    kevent_add(kqfd, &kev, SIGUSR1, EVFILT_SIGNAL, EV_ADD, 0, 0, ((void *)-1));

    if (kill(getpid(), SIGUSR1) < 0)
        die("kill");

    kev.flags |= EV_CLEAR;
    kev.data = 1;
    kevent_cmp(&kev, kevent_get(kqfd));
}

#if HAVE_EV_DISPATCH
void
test_kevent_signal_dispatch(void)
{
    struct kevent kev;

    test_no_kevents(kqfd);

    kevent_add(kqfd, &kev, SIGUSR1, EVFILT_SIGNAL, EV_ADD | EV_CLEAR | EV_DISPATCH, 0, 0, NULL);

    /* Get one event */
    if (kill(getpid(), SIGUSR1) < 0)
        die("kill");
    kev.data = 1;
    kevent_cmp(&kev, kevent_get(kqfd));

    /* Confirm that the knote is disabled */
    if (kill(getpid(), SIGUSR1) < 0)
        die("kill");
    test_no_kevents(kqfd);

    /* Enable the knote and make sure no events are pending */
    kevent_add(kqfd, &kev, SIGUSR1, EVFILT_SIGNAL, EV_ENABLE | EV_DISPATCH, 0, 0, NULL);
    test_no_kevents(kqfd);

    /* Get the next event */
    if (kill(getpid(), SIGUSR1) < 0)
        die("kill");
    kev.flags = EV_ADD | EV_CLEAR | EV_DISPATCH;
    kev.data = 1;
    kevent_cmp(&kev, kevent_get(kqfd));

    /* Remove the knote and ensure the event no longer fires */
    kevent_add(kqfd, &kev, SIGUSR1, EVFILT_SIGNAL, EV_DELETE, 0, 0, NULL);
    if (kill(getpid(), SIGUSR1) < 0)
        die("kill");
    test_no_kevents(kqfd);
}
#endif  /* HAVE_EV_DISPATCH */

void
test_evfilt_signal(int _kqfd)
{
    signal(SIGUSR1, SIG_IGN);

	kqfd = _kqfd;
    test(kevent_signal_add);
    test(kevent_signal_del);
    test(kevent_signal_get);
    test(kevent_signal_disable);
    test(kevent_signal_enable);
    test(kevent_signal_oneshot);
    test(kevent_signal_modify);
#if HAVE_EV_DISPATCH
    test(kevent_signal_dispatch);
#endif
}
