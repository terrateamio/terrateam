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

#include <sys/types.h>
#include <poll.h>

#include "common.h"

struct unit_test {
    const char *ut_name;
    int         ut_enabled;
    void      (*ut_func)(int);
};

/*
 * Test the method for detecting when one end of a socketpair 
 * has been closed. This technique is used in kqueue_validate()
 */
static void
test_peer_close_detection(void)
{
    int sockfd[2];
    char buf[1];
    struct pollfd pfd;

    if (socketpair(AF_UNIX, SOCK_STREAM, 0, sockfd) < 0)
        die("socketpair");

    pfd.fd = sockfd[0];
    pfd.events = POLLIN | POLLHUP;
    pfd.revents = 0;

    if (poll(&pfd, 1, 0) > 0) 
        die("unexpected data");

    if (close(sockfd[1]) < 0)
        die("close");

    if (poll(&pfd, 1, 0) > 0) {
        if (recv(sockfd[0], buf, sizeof(buf), MSG_PEEK | MSG_DONTWAIT) != 0) 
            die("failed to detect peer shutdown");
    }
}

void
test_kqueue(void)
{
    int kqfd;

    if ((kqfd = kqueue()) < 0)
        die("kqueue()");
    test_no_kevents(kqfd);
    if (close(kqfd) < 0)
        die("close()");
}

void
test_ev_receipt(void)
{
    int kq;
    struct kevent kev;

    if ((kq = kqueue()) < 0)
        die("kqueue()");
#if HAVE_EV_RECEIPT

    EV_SET(&kev, SIGUSR2, EVFILT_SIGNAL, EV_ADD | EV_RECEIPT, 0, 0, NULL);
    if (kevent(kq, &kev, 1, &kev, 1, NULL) < 0)
        die("kevent");

    /* TODO: check the receipt */

    close(kq);
#else
    memset(&kev, 0, sizeof(kev));
    puts("Skipped -- EV_RECEIPT is not available");
#endif
}

int 
main(int argc, char **argv)
{
    struct unit_test tests[] = {
        { "socket", 1, test_evfilt_read },
        { "signal", 1, test_evfilt_signal },
#if FIXME
        { "proc", 1, test_evfilt_proc },
#endif
        { "vnode", 1, test_evfilt_vnode },
        { "timer", 1, test_evfilt_timer },
#if HAVE_EVFILT_USER
        { "user", 1, test_evfilt_user },
#endif
        { NULL, 0, NULL },
    };
    struct unit_test *test;
    int kqfd;

    /* Enable all tests by default */
    if (argc == 0)
        for (test = &tests[0]; test->ut_name != NULL; test++) {
            test->ut_enabled = 1;
        }

    while (argc) {
        for (test = &tests[0]; test->ut_name != NULL; test++) {
            if (strcmp(argv[0], test->ut_name) == 0) {
                test->ut_enabled = 1;
                break;
            }
        }
        argv++;
        argc--;
    }

    testing_begin();

    test(peer_close_detection);

    test(kqueue);

    if ((kqfd = kqueue()) < 0)
        die("kqueue()");

    for (test = &tests[0]; test->ut_name != NULL; test++) {
        test->ut_func(kqfd);
    }

    test(ev_receipt);

    testing_end();

    return (0);
}
