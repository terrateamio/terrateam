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
static int __thread sockfd[2];

static void
kevent_socket_drain(void)
{
    char buf[1];

    /* Drain the read buffer, then make sure there are no more events. */
    if (read(sockfd[0], &buf[0], 1) < 1)
        die("read(2)");
}

static void
kevent_socket_fill(void)
{
    if (write(sockfd[1], ".", 1) < 1)
        die("write(2)");
}


void
test_kevent_socket_add(void)
{
    struct kevent kev;

    kevent_add(kqfd, &kev, sockfd[0], EVFILT_READ, EV_ADD, 0, 0, &sockfd[0]);
}

void
test_kevent_socket_add_without_ev_add(void)
{
    struct kevent kev;

    /* Try to add a kevent without specifying EV_ADD */
    EV_SET(&kev, sockfd[0], EVFILT_READ, 0, 0, 0, &sockfd[0]);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) == 0)
        die("kevent should have failed");

    kevent_socket_fill();
    test_no_kevents(kqfd);
    kevent_socket_drain();

    /* Try to delete a kevent which does not exist */
    kev.flags = EV_DELETE;
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) == 0)
        die("kevent should have failed");
}

void
test_kevent_socket_get(void)
{
    struct kevent kev;

    EV_SET(&kev, sockfd[0], EVFILT_READ, EV_ADD, 0, 0, &sockfd[0]);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        die("kevent");

    kevent_socket_fill();

    kev.data = 1;
    kevent_cmp(&kev, kevent_get(kqfd));

    kevent_socket_drain();
    test_no_kevents(kqfd);

    kev.flags = EV_DELETE;
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        die("kevent");
}

void
test_kevent_socket_clear(void)
{
    struct kevent kev;

    test_no_kevents(kqfd);
    kevent_socket_drain();

    EV_SET(&kev, sockfd[0], EVFILT_READ, EV_ADD | EV_CLEAR, 0, 0, &sockfd[0]);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        die("kevent");

    kevent_socket_fill();
    kevent_socket_fill();

/* Solaris does not offer a way to get the amount of data pending */
#if defined(__sun__)
    kev.data = 1;
#else
    kev.data = 2;
#endif
    kevent_cmp(&kev, kevent_get(kqfd)); 

    /* We filled twice, but drain once. Edge-triggered would not generate
       additional events.
     */
    kevent_socket_drain();
    test_no_kevents(kqfd);

    kevent_socket_drain();
    EV_SET(&kev, sockfd[0], EVFILT_READ, EV_DELETE, 0, 0, &sockfd[0]);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        die("kevent");
}

void
test_kevent_socket_disable_and_enable(void)
{
    struct kevent kev;

    /* Add an event, then disable it. */
    EV_SET(&kev, sockfd[0], EVFILT_READ, EV_ADD, 0, 0, &sockfd[0]);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        die("kevent");
    EV_SET(&kev, sockfd[0], EVFILT_READ, EV_DISABLE, 0, 0, &sockfd[0]);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        die("kevent");

    kevent_socket_fill();
    test_no_kevents(kqfd);

    /* Re-enable the knote, then see if an event is generated */
    kev.flags = EV_ENABLE;
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        die("kevent");
    kev.flags = EV_ADD;
    kev.data = 1;
    kevent_cmp(&kev, kevent_get(kqfd));

    kevent_socket_drain();

    kev.flags = EV_DELETE;
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        die("kevent");
}

void
test_kevent_socket_del(void)
{
    struct kevent kev;

    EV_SET(&kev, sockfd[0], EVFILT_READ, EV_DELETE, 0, 0, &sockfd[0]);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        die("kevent");

    kevent_socket_fill();
    test_no_kevents(kqfd);
    kevent_socket_drain();
}

void
test_kevent_socket_oneshot(void)
{
    struct kevent kev;

    /* Re-add the watch and make sure no events are pending */
    kevent_add(kqfd, &kev, sockfd[0], EVFILT_READ, EV_ADD | EV_ONESHOT, 0, 0, &sockfd[0]);
    test_no_kevents(kqfd);

    kevent_socket_fill();
    kev.data = 1;
    kevent_cmp(&kev, kevent_get(kqfd));

    test_no_kevents(kqfd);

    /* Verify that the event has been deleted */
    kevent_socket_fill();
    test_no_kevents(kqfd);
    kevent_socket_drain();
}

/*
 * Test if the data field returns 1 when a listen(2) socket has
 * a pending connection.
 */
void
test_kevent_socket_listen_backlog(void)
{
    struct kevent kev;
    struct sockaddr_in sain;
    socklen_t sa_len = sizeof(sain);
    int one = 1;
    const short port = 14973;
    int clnt, srvr;

    /* Create a passive socket */
    memset(&sain, 0, sizeof(sain));
    sain.sin_family = AF_INET;
    sain.sin_port = htons(port);
    if ((srvr = socket(PF_INET, SOCK_STREAM, 0)) < 0) abort();
    if (setsockopt(srvr, SOL_SOCKET, SO_REUSEADDR, 
                (char *) &one, sizeof(one)) != 0) abort();
    if (bind(srvr, (struct sockaddr *) &sain, sa_len) < 0) abort();
    if (listen(srvr, 100) < 0) abort();

    /* Watch for events on the socket */
    test_no_kevents(kqfd);
    kevent_add(kqfd, &kev, srvr, EVFILT_READ, EV_ADD | EV_ONESHOT, 0, 0, NULL);
    test_no_kevents(kqfd);

    /* Simulate a client connecting to the server */
    sain.sin_family = AF_INET;
    sain.sin_port = htons(port);
    sain.sin_addr.s_addr = inet_addr("127.0.0.1");
    if ((clnt = socket(AF_INET, SOCK_STREAM, 0)) < 0) abort();
    if (connect(clnt, (struct sockaddr *) &sain, sa_len) < 0) abort();

    /* Verify that data=1 */
    kev.data = 1;
    kevent_cmp(&kev, kevent_get(kqfd));
    test_no_kevents(kqfd);
}

#if HAVE_EV_DISPATCH
void
test_kevent_socket_dispatch(void)
{
    struct kevent kev;

    /* Re-add the watch and make sure no events are pending */
    kevent_add(kqfd, &kev, sockfd[0], EVFILT_READ, EV_ADD | EV_DISPATCH, 0, 0, &sockfd[0]);
    test_no_kevents(kqfd);

    /* The event will occur only once, even though EV_CLEAR is not
       specified. */
    kevent_socket_fill();
    kev.data = 1;
    kevent_cmp(&kev, kevent_get(kqfd));
    test_no_kevents(kqfd);

    /* Re-enable the kevent */
    /* FIXME- is EV_DISPATCH needed when rearming ? */
    kevent_add(kqfd, &kev, sockfd[0], EVFILT_READ, EV_ENABLE | EV_DISPATCH, 0, 0, &sockfd[0]);
    kev.data = 1;
    kev.flags = EV_ADD | EV_DISPATCH;   /* FIXME: may not be portable */
    kevent_cmp(&kev, kevent_get(kqfd));
    test_no_kevents(kqfd);

    /* Since the knote is disabled, the EV_DELETE operation succeeds. */
    kevent_add(kqfd, &kev, sockfd[0], EVFILT_READ, EV_DELETE, 0, 0, &sockfd[0]);

    kevent_socket_drain();
}
#endif  /* HAVE_EV_DISPATCH */

#if BROKEN_ON_LINUX
void
test_kevent_socket_lowat(void)
{
    struct kevent kev;

    test_begin(test_id);

    /* Re-add the watch and make sure no events are pending */
    puts("-- re-adding knote, setting low watermark to 2 bytes");
    EV_SET(&kev, sockfd[0], EVFILT_READ, EV_ADD | EV_ONESHOT, NOTE_LOWAT, 2, &sockfd[0]);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        die("%s", test_id);
    test_no_kevents();

    puts("-- checking that one byte does not trigger an event..");
    kevent_socket_fill();
    test_no_kevents();

    puts("-- checking that two bytes triggers an event..");
    kevent_socket_fill();
    if (kevent(kqfd, NULL, 0, &kev, 1, NULL) != 1)
        die("%s", test_id);
    KEV_CMP(kev, sockfd[0], EVFILT_READ, 0);
    test_no_kevents();

    kevent_socket_drain();
    kevent_socket_drain();
}
#endif

void
test_kevent_socket_eof(void)
{
    struct kevent kev;

    /* Re-add the watch and make sure no events are pending */
    kevent_add(kqfd, &kev, sockfd[0], EVFILT_READ, EV_ADD, 0, 0, &sockfd[0]);
    test_no_kevents(kqfd);

    if (close(sockfd[1]) < 0)
        die("close(2)");

    kev.flags |= EV_EOF;
    kevent_cmp(&kev, kevent_get(kqfd));

    /* Delete the watch */
    kevent_add(kqfd, &kev, sockfd[0], EVFILT_READ, EV_DELETE, 0, 0, &sockfd[0]);
}

void
test_evfilt_read(int _kqfd)
{
#ifdef _WIN32
	die("XXX-FIXME");
#else
    /* Create a connected pair of full-duplex sockets for testing socket events */
    if (socketpair(AF_UNIX, SOCK_STREAM, 0, sockfd) < 0) 
        die("socketpair");
#endif

    kqfd = _kqfd;
    test(kevent_socket_add);
    test(kevent_socket_del);
    test(kevent_socket_add_without_ev_add);
    test(kevent_socket_get);
    test(kevent_socket_disable_and_enable);
    test(kevent_socket_oneshot);
    test(kevent_socket_clear);
#if HAVE_EV_DISPATCH
    test(kevent_socket_dispatch);
#endif
    test(kevent_socket_listen_backlog);
    test(kevent_socket_eof);
    close(sockfd[0]);
    close(sockfd[1]);
}
