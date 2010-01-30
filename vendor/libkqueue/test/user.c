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

static void
test_kevent_user_add_and_delete(void)
{
    struct kevent kev;

    kevent_add(kqfd, &kev, 1, EVFILT_USER, EV_ADD, 0, 0, NULL);
    test_no_kevents();

    kevent_add(kqfd, &kev, 1, EVFILT_USER, EV_DELETE, 0, 0, NULL);
    test_no_kevents();
}

static void
test_kevent_user_get(void)
{
    struct kevent kev;

    test_no_kevents();

    /* Add the event, and then trigger it */
    kevent_add(kqfd, &kev, 1, EVFILT_USER, EV_ADD | EV_CLEAR, 0, 0, NULL);    
    kevent_add(kqfd, &kev, 1, EVFILT_USER, 0, NOTE_TRIGGER, 0, NULL);    

    kev.fflags &= ~NOTE_FFCTRLMASK;
    kev.fflags &= ~NOTE_TRIGGER;
    kev.flags = EV_CLEAR;
    kevent_cmp(&kev, kevent_get(kqfd));

    test_no_kevents();
}

static void
test_kevent_user_disable_and_enable(void)
{
    struct kevent kev;

    test_no_kevents();

    kevent_add(kqfd, &kev, 1, EVFILT_USER, EV_ADD, 0, 0, NULL); 
    kevent_add(kqfd, &kev, 1, EVFILT_USER, EV_DISABLE, 0, 0, NULL); 

    /* Trigger the event, but since it is disabled, nothing will happen. */
    kevent_add(kqfd, &kev, 1, EVFILT_USER, 0, NOTE_TRIGGER, 0, NULL); 
    test_no_kevents();

    kevent_add(kqfd, &kev, 1, EVFILT_USER, EV_ENABLE, 0, 0, NULL); 
    kevent_add(kqfd, &kev, 1, EVFILT_USER, 0, NOTE_TRIGGER, 0, NULL); 

    kev.flags = EV_CLEAR;
    kev.fflags &= ~NOTE_FFCTRLMASK;
    kev.fflags &= ~NOTE_TRIGGER;
    kevent_cmp(&kev, kevent_get(kqfd));
}

static void
test_kevent_user_oneshot(void)
{
    struct kevent kev;


    test_no_kevents();

    kevent_add(kqfd, &kev, 2, EVFILT_USER, EV_ADD | EV_ONESHOT, 0, 0, NULL);

    puts("  -- event 1");
    kevent_add(kqfd, &kev, 2, EVFILT_USER, 0, NOTE_TRIGGER, 0, NULL);    

    kev.flags = EV_ONESHOT;
    kev.fflags &= ~NOTE_FFCTRLMASK;
    kev.fflags &= ~NOTE_TRIGGER;
    kevent_cmp(&kev, kevent_get(kqfd));

    test_no_kevents();
}

void
test_evfilt_user()
{
	kqfd = kqueue();

    test(kevent_user_add_and_delete);
    test(kevent_user_get);
    test(kevent_user_disable_and_enable);
    test(kevent_user_oneshot);
    /* TODO: try different fflags operations */

	close(kqfd);
}
