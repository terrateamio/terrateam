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

#if defined(__linux__) || defined(__FreeBSD__)
#include <sys/resource.h>
#endif

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
test_kqueue_alloc(void *unused)
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
    if (max_fds < curr_rlim.rlim_cur) {
        /* Set FD limit to MAX_FDS */
        rlim = curr_rlim;
        rlim.rlim_cur = 32;
        if (setrlimit(RLIMIT_NOFILE, &rlim) < 0) {
            die("setrlimit failed");
        }
    } else {
        max_fds = curr_rlim.rlim_cur;
    }

    /* Create initial kqueue to avoid cleanup thread being destroyed on each close */
    if ((kqfd1 = kqueue()) < 0)
        die("kqueue() - used_fds=%u max_fds=%u", print_fd_table(), max_fds);

    /* Create and close 2 * max fd number of kqueues */
    for (i=0; i < 2 * max_fds + 1; i++) {
        if ((kqfd2 = kqueue()) < 0)
            die("kqueue() - i=%i used_fds=%u max_fds=%u", i, print_fd_table(), max_fds);

        kevent_add(kqfd2, &kev, 1, EVFILT_TIMER, EV_ADD, 0, 1000, NULL);

        if (close(kqfd2) < 0)
            die("close()");

        nanosleep(&(struct timespec) { .tv_nsec = 25000000 }, NULL);   /* deschedule thread */
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

        kevent_add(kqfd2, &kev, 1, EVFILT_TIMER, EV_ADD, 0, 1000, NULL);

        if (close(kqfd2) < 0)
            die("close()");

        nanosleep(&(struct timespec) { .tv_nsec = 25000000 }, NULL);   /* deschedule thread */
    }

    /* Restore FD limit */
    if (setrlimit(RLIMIT_NOFILE, &curr_rlim) < 0) {
        die("setrlimit failed");
    }
}

void
test_fork(void *unused)
{
    int kqfd;
    pid_t pid;

    kqfd = kqueue();
    if (kqfd < 0)
        die("kqueue()");

    pid = fork();
    if (pid == 0) {
        /*
         * fork should immediately close all open
         * kqueues and their file descriptors.
         */
        if (close(kqfd) != -1)
           die("kqueue fd still open in child");

        testing_end_quiet();
        exit(0);
    } else if (pid == -1)
        die("fork()");

    close(kqfd);
}
#endif

/* EV_RECEIPT is not available or running on Win32 */
#if !defined(_WIN32)
void
test_ev_receipt(struct test_context *ctx)
{
    struct kevent kev;
    struct kevent buf;

    EV_SET(&kev, SIGUSR2, EVFILT_SIGNAL, EV_ADD | EV_ERROR | EV_RECEIPT, 0, 0, NULL);
    buf = kev;

    kevent_rv_cmp(1, kevent(ctx->kqfd, &kev, 1, &buf, 1, NULL));

#ifdef __FreeBSD__
    /*
     *  macOS and libkqueue both return
     *  EV_RECEIPT here FreeBSD does not.
     */
    kev.flags ^= EV_RECEIPT;
#endif

    kevent_cmp(&kev, &buf);
}
#endif

/* Maximum number of threads that can be created */
#define MAX_THREADS 100

/**
 * Don't build the below function on OSX due to a known-issue
 * breaking the build with FD_SET()/FD_ISSET() + OSX.
 * e.g: https://www.google.com/search?q=___darwin_check_fd_set_overflow
 */
#ifndef __APPLE__
void
test_kqueue_descriptor_is_pollable(void *unused)
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
#endif

void
test_kqueue(struct test_context *ctx)
{
    test(peer_close_detection, ctx);

    test(kqueue_alloc, ctx);
    test(kevent, ctx);

#if defined(__linux__)
    test(cleanup, ctx);

    /*
     * Only run the fork test if we can do TSAN
     * suppressions, as there's false positives
     * generated by libkqueue_pre_fork.
     */
#  ifdef HAVE_TSAN_IGNORE
    test(fork, ctx);
#  endif
#endif

#if !defined(_WIN32)
    test(ev_receipt, ctx);
#endif
    /* TODO: this fails now, but would be good later
    test(kqueue_descriptor_is_pollable, ctx);
    */
}


