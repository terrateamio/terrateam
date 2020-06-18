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

#if defined(__linux__)
#include <sys/time.h>
#include <sys/resource.h>
#endif
#include "common.h"

/* Maximum number of threads that can be created */
#define MAX_THREADS 100

void
test_kqueue_descriptor_is_pollable(void)
{
    int kq, rv;
    struct kevent kev;
    fd_set fds;
    struct timeval tv;

    if ((kq = kqueue()) < 0)
        die("kqueue()");

    test_no_kevents(kq);
    kevent_add(kq, &kev, 2, EVFILT_TIMER, EV_ADD | EV_ONESHOT, 0, 1000, NULL);
    test_no_kevents(kq);

    FD_ZERO(&fds);
    FD_SET(kq, &fds);
    tv.tv_sec = 5;
    tv.tv_usec = 0;
    rv = select(1, &fds, NULL, NULL, &tv);
    if (rv < 0)
        die("select() error");
    if (rv == 0)
        die("select() no events");
    if (!FD_ISSET(kq, &fds)) {
        die("descriptor is not ready for reading");
    }

    close(kq);
}

/*
 * Test the method for detecting when one end of a socketpair
 * has been closed. This technique is used in kqueue_validate()
 */
static void
test_peer_close_detection(void *unused)
{
#ifdef _WIN32
    return;
    //FIXME
#else
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
    close(sockfd[0]);
#endif
}

void
test_kqueue(void *unused)
{
    int kqfd;

    if ((kqfd = kqueue()) < 0)
        die("kqueue()");
    test_no_kevents(kqfd);
    if (close(kqfd) < 0)
        die("close()");
}

void
test_kevent(void *unused)
{
    struct kevent kev;

    memset(&kev, 0, sizeof(kev));

    /* Provide an invalid kqueue descriptor */
    if (kevent(-1, &kev, 1, NULL, 0, NULL) == 0)
        die("invalid kq parameter");
}

#if defined(__linux__)
/* Maximum number of FD for current process */
#define MAX_FDS 32
/*
 * Test the cleanup process for Linux
 */
void
test_cleanup(void *unused)
{
    int i;
    int max_fds = MAX_FDS;
    struct rlimit curr_rlim, rlim;
    int kqfd1, kqfd2;
    struct kevent kev;

    /* Remeber current FD limit */
    if (getrlimit(RLIMIT_NOFILE, &curr_rlim) < 0) {
        die("getrlimit failed");
    }

    /* lower FD limit to 32 */
    if (max_fds < rlim.rlim_cur) {
        /* Set FD limit to MAX_FDS */
        rlim = curr_rlim;
        rlim.rlim_cur = 32;
        if (setrlimit(RLIMIT_NOFILE, &rlim) < 0) {
            die("setrlimit failed");
        }
    } else {
        max_fds = rlim.rlim_cur;
    }

    /* Create initial kqueue to avoid cleanup thread being destroyed on each close */
    if ((kqfd1 = kqueue()) < 0)
        die("kqueue() - max_fds=%u", max_fds);

    /* Create and close 2 * max fd number of kqueues */
    for (i=0; i < 2 * max_fds + 1; i++) {
        if ((kqfd2 = kqueue()) < 0)
            die("kqueue() - i=%i max_fds=%u", i, max_fds);

        kevent_add(kqfd2, &kev, 1, EVFILT_TIMER, EV_ADD, 0, 1000,NULL);

        if (close(kqfd2) < 0)
            die("close()");
    }

    if (close(kqfd1) < 0)
        die("close()");

    /*
     * Run same test again but without extra kqueue
     * Cleanup thread will be destroyed
     * Create and close 2 * max fd number of kqueues
     */
    for (i=0; i < 2 * max_fds + 1; i++) {
        if ((kqfd2 = kqueue()) < 0)
            die("kqueue()");

        kevent_add(kqfd2, &kev, 1, EVFILT_TIMER, EV_ADD, 0, 1000,NULL);

        if (close(kqfd2) < 0)
            die("close()");
    }

    /* Restore FD limit */
    if (setrlimit(RLIMIT_NOFILE, &curr_rlim) < 0) {
        die("setrlimit failed");
    }
}
#endif

void
test_ev_receipt(void *unused)
{
    int kq;
    struct kevent kev;

    if ((kq = kqueue()) < 0)
        die("kqueue()");
#if !defined(_WIN32)
    EV_SET(&kev, SIGUSR2, EVFILT_SIGNAL, EV_ADD | EV_RECEIPT, 0, 0, NULL);
    if (kevent(kq, &kev, 1, &kev, 1, NULL) < 0)
        die("kevent");
#else
    memset(&kev, 0, sizeof(kev));
    puts("Skipped -- EV_RECEIPT is not available or running on Win32");
#endif
    close(kq);
}

void
run_iteration(struct test_context *ctx)
{
    struct unit_test *test;

    for (test = ctx->tests; test->ut_name != NULL; test++) {
        if (test->ut_enabled)
            test->ut_func(ctx);
    }
    free(ctx);
}

void
test_harness(struct unit_test tests[MAX_TESTS], int iterations)
{
    int i, n, kqfd;
    struct test_context *ctx;

    printf("Running %d iterations\n", iterations);

    testing_begin();

    ctx = calloc(1, sizeof(*ctx));

    test(peer_close_detection, ctx);

    test(kqueue, ctx);
    test(kevent, ctx);

#if defined(__linux__)
    test(cleanup, ctx);
#endif

    if ((kqfd = kqueue()) < 0)
        die("kqueue()");

    test(ev_receipt, ctx);
    /* TODO: this fails now, but would be good later
    test(kqueue_descriptor_is_pollable);
    */

    free(ctx);

    n = 0;
    for (i = 0; i < iterations; i++) {
        ctx = calloc(1, sizeof(*ctx));
        if (ctx == NULL)
            abort();
        ctx->iteration = n++;
        ctx->kqfd = kqfd;
        memcpy(&ctx->tests, tests, sizeof(ctx->tests));
        ctx->iterations = iterations;

        run_iteration(ctx);
    }
    testing_end();

    close(kqfd);
}

void
usage(void)
{
    printf("usage: [-hn] [testclass ...]\n"
           " -h        This message\n"
           " -n        Number of iterations (default: 1)\n"
           " testclass Tests suites to run: [socket signal timer vnode user]\n"
           "           All tests are run by default\n"
           "\n"
          );
    exit(1);
}

int
main(int argc, char **argv)
{
    struct unit_test tests[MAX_TESTS] = {
        { "socket", 1, test_evfilt_read },
#if !defined(_WIN32) && !defined(__ANDROID__)
        // XXX-FIXME -- BROKEN ON LINUX WHEN RUN IN A SEPARATE THREAD
        { "signal", 1, test_evfilt_signal },
#endif
#if FIXME
        { "proc", 1, test_evfilt_proc },
#endif
        { "timer", 1, test_evfilt_timer },
#ifndef _WIN32
        { "vnode", 1, test_evfilt_vnode },
#endif
#ifdef EVFILT_USER
        { "user", 1, test_evfilt_user },
#endif
        { NULL, 0, NULL },
    };
    struct unit_test *test;
    int c, i, iterations;
    char *arg;
    int match;

#ifdef _WIN32
    /* Initialize the Winsock library */
    WSADATA wsaData;
    if (WSAStartup(MAKEWORD(2,2), &wsaData) != 0)
        err(1, "WSAStartup failed");
#endif

    iterations = 1;

/* Windows does not provide a POSIX-compatible getopt */
#ifndef _WIN32
    while ((c = getopt (argc, argv, "hn:")) != -1) {
        switch (c) {
            case 'h':
                usage();
                break;
            case 'n':
                iterations = atoi(optarg);
                break;
            default:
                usage();
        }
    }

    /* If specific tests are requested, disable all tests by default */
    if (optind < argc) {
        for (test = tests; test->ut_name != NULL; test++) {
            test->ut_enabled = 0;
        }
    }
    for (i = optind; i < argc; i++) {
        match = 0;
        arg = argv[i];
        for (test = tests; test->ut_name != NULL; test++) {
            if (strcmp(arg, test->ut_name) == 0) {
                test->ut_enabled = 1;
                match = 1;
                break;
            }
        }
        if (!match) {
            printf("ERROR: invalid option: %s\n", arg);
            exit(1);
        } else {
            printf("enabled test: %s\n", arg);
        }
    }
#endif

    test_harness(tests, iterations);

    return (0);
}
