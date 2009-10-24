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

#ifdef UNIT_TEST

#include <err.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

#include "sys/event.h"

char *cur_test_id = "undef";
int kqfd;
int sockfd[2];
int vnode_fd;

/* In kevent.c */
const char * kevent_dump(struct kevent *);

#define KEV_CMP(kev,_ident,_filter,_flags) do {                 \
    if (kev.ident != (_ident) ||                                \
            kev.filter != (_filter) ||                          \
            kev.flags != (_flags)) \
        err(1, "kevent mismatch: got %s but expecting [%d,%d,%d]", \
                kevent_dump(&kev),\
                (int)kev.ident, kev.filter, kev.flags);\
} while (0);

/* Checks if any events are pending, which is an error. */
void 
test_no_kevents(void)
{
    int nfds;
    struct timespec timeo;
    struct kevent kev;

    puts("confirming that there are no events pending");
    memset(&timeo, 0, sizeof(timeo));
    nfds = kevent(kqfd, NULL, 0, &kev, 1, &timeo);
    if (nfds != 0) {
        puts(kevent_dump(&kev));
        errx(1, "%d event(s) pending, but none expected:", nfds);
    }
}


void
test_begin(const char *func)
{
    static int testnum = 1;
    cur_test_id = (char *) func;
    printf("\n\nTest %d: %s\n", testnum++, func);
}

void
success(const char *func)
{
    printf("%-70s %s\n", func, "passed");
}

void
test_kqueue(void)
{
    test_begin("kqueue()");
    if ((kqfd = kqueue()) < 0)
        err(1, "kqueue()");
    test_no_kevents();
    success("kqueue()");
}

void
test_kqueue_close(void)
{
    test_begin("close(kq)");
    if (close(kqfd) < 0)
        err(1, "close()");
    success("kqueue_close()");
}

void
test_kevent_socket_add(void)
{
    const char *test_id = "kevent(EVFILT_READ, EV_ADD)";
    struct kevent kev;

    test_begin(test_id);
    EV_SET(&kev, sockfd[0], EVFILT_READ, EV_ADD, 0, 0, &sockfd[0]);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    success(test_id);
}

void
test_kevent_socket_get(void)
{
    const char *test_id = "kevent(EVFILT_READ) wait";
    char buf[1];
    struct kevent kev;
    int nfds;

    test_begin(test_id);

    if (write(sockfd[1], ".", 1) < 1)
        err(1, "write(2)");

    nfds = kevent(kqfd, NULL, 0, &kev, 1, NULL);
    if (nfds < 1)
        err(1, "%s", test_id);
    KEV_CMP(kev, sockfd[0], EVFILT_READ, 0);
    if ((int)kev.data != 1)
        err(1, "incorrect data value %d", (int) kev.data); // FIXME: make part of KEV_CMP

    /* Drain the read buffer, then make sure there are no more events. */
    puts("draining the read buffer");
    if (read(sockfd[0], &buf[0], 1) < 1)
        err(1, "read(2)");
    test_no_kevents();

    success(test_id);
}

void
test_kevent_socket_disable(void)
{
    const char *test_id = "kevent(EVFILT_READ, EV_DISABLE)";
    struct kevent kev;

    test_begin(test_id);

    EV_SET(&kev, sockfd[0], EVFILT_READ, EV_DISABLE, 0, 0, &sockfd[0]);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    puts("filling the read buffer");
    if (write(sockfd[1], ".", 1) < 1)
        err(1, "write(2)");
    test_no_kevents();

    success(test_id);
}

void
test_kevent_socket_enable(void)
{
    const char *test_id = "kevent(EVFILT_READ, EV_ENABLE)";
    struct kevent kev;
    int nfds;

    test_begin(test_id);

    EV_SET(&kev, sockfd[0], EVFILT_READ, EV_ENABLE, 0, 0, &sockfd[0]);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    nfds = kevent(kqfd, NULL, 0, &kev, 1, NULL);
    if (nfds < 1)
        err(1, "%s", test_id);
    KEV_CMP(kev, sockfd[0], EVFILT_READ, 0);

    success(test_id);
}

void
test_kevent_socket_del(void)
{
    const char *test_id = "kevent(EVFILT_READ, EV_DELETE)";
    struct kevent kev;
    char buf[100];

    test_begin(test_id);

    EV_SET(&kev, sockfd[0], EVFILT_READ, EV_DELETE, 0, 0, &sockfd[0]);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    puts("filling the read buffer");
    if (write(sockfd[1], ".", 1) < 1)
        err(1, "write(2)");
    test_no_kevents();
    if (read(sockfd[0], &buf[0], sizeof(buf)) < 1)
        err(1, "read(2)");

    success(test_id);
}

void
test_kevent_socket_eof(void)
{
    const char *test_id = "kevent(EVFILT_READ, EV_EOF)";
    struct kevent kev;

    test_begin(test_id);

    /* Re-add the watch and make sure no events are pending */
    EV_SET(&kev, sockfd[0], EVFILT_READ, EV_ADD, 0, 0, &sockfd[0]);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);
    test_no_kevents();

    if (close(sockfd[1]) < 0)
        err(1, "close(2)");

    if (kevent(kqfd, NULL, 0, &kev, 1, NULL) < 1)
        err(1, "%s", test_id);
    KEV_CMP(kev, sockfd[0], EVFILT_READ, EV_EOF);

    success(test_id);
}


void
test_kevent_signal_add(void)
{
    const char *test_id = "kevent(EVFILT_SIGNAL, EV_ADD)";
    struct kevent kev;

    test_begin(test_id);

    EV_SET(&kev, SIGUSR1, EVFILT_SIGNAL, EV_ADD, 0, 0, &sockfd[0]);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    success(test_id);
}

void
test_kevent_signal_get(void)
{
    const char *test_id = "kevent(get signal)";
    struct kevent kev;
    int nfds;

    test_begin(test_id);

    /* Block SIGUSR1, then send it to ourselves */
    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, SIGUSR1);
    if (sigprocmask(SIG_BLOCK, &mask, NULL) == -1)
        err(1, "sigprocmask");
    if (kill(getpid(), SIGUSR1) < 0)
        err(1, "kill");

    nfds = kevent(kqfd, NULL, 0, &kev, 1, NULL);
    if (nfds < 1)
        err(1, "test failed: %s, retval %d", test_id, nfds);
    if (kev.ident != SIGUSR1 ||
            kev.filter != EVFILT_SIGNAL || 
            kev.flags != 0)
        err(1, "%s - incorrect event (sig=%u; filt=%d; flags=%d)", 
                test_id, (unsigned int)kev.ident, kev.filter, kev.flags);
    //FIXME: test kev->flags, fflags, data

    success(test_id);
}

void
test_kevent_signal_disable(void)
{
    const char *test_id = "kevent(EVFILT_SIGNAL, EV_DISABLE)";
    struct kevent kev;

    test_begin(test_id);

    EV_SET(&kev, SIGUSR1, EVFILT_SIGNAL, EV_DISABLE, 0, 0, &sockfd[0]);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    /* Block SIGUSR1, then send it to ourselves */
    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, SIGUSR1);
    if (sigprocmask(SIG_BLOCK, &mask, NULL) == -1)
        err(1, "sigprocmask");
    if (kill(getpid(), SIGUSR1) < 0)
        err(1, "kill");

    test_no_kevents();

    success(test_id);
}

void
test_kevent_signal_enable(void)
{
    const char *test_id = "kevent(EVFILT_SIGNAL, EV_ENABLE)";
    struct kevent kev;
    int nfds;

    test_begin(test_id);

    EV_SET(&kev, SIGUSR1, EVFILT_SIGNAL, EV_ENABLE, 0, 0, &sockfd[0]);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    /* Block SIGUSR1, then send it to ourselves */
    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, SIGUSR1);
    if (sigprocmask(SIG_BLOCK, &mask, NULL) == -1)
        err(1, "sigprocmask");
    if (kill(getpid(), SIGUSR1) < 0)
        err(1, "kill");


    nfds = kevent(kqfd, NULL, 0, &kev, 1, NULL);
    if (nfds < 1)
        err(1, "test failed: %s, retval %d", test_id, nfds);
    if (kev.ident != SIGUSR1 ||
            kev.filter != EVFILT_SIGNAL || 
            kev.flags != 0)
        err(1, "%s - incorrect event (sig=%u; filt=%d; flags=%d)", 
                test_id, (unsigned int)kev.ident, kev.filter, kev.flags);

    success(test_id);
}

void
test_kevent_signal_del(void)
{
    const char *test_id = "kevent(EVFILT_SIGNAL, EV_DELETE)";
    struct kevent kev;

    test_begin(test_id);

    /* Delete the kevent */
    EV_SET(&kev, SIGUSR1, EVFILT_SIGNAL, EV_DELETE, 0, 0, &sockfd[0]);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    /* Block SIGUSR1, then send it to ourselves */
    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, SIGUSR1);
    if (sigprocmask(SIG_BLOCK, &mask, NULL) == -1)
        err(1, "sigprocmask");
    if (kill(getpid(), SIGUSR1) < 0)
        err(1, "kill");

    test_no_kevents();
    success(test_id);
}

void
test_kevent_vnode_add(void)
{
    const char *test_id = "kevent(EVFILT_VNODE, EV_ADD)";
    const char *testfile = "/tmp/kqueue-test.tmp";
    struct kevent kev;

    test_begin(test_id);

    system("touch /tmp/kqueue-test.tmp");
    vnode_fd = open(testfile, O_RDONLY);
    if (vnode_fd < 0)
        err(1, "open of %s", testfile);
    else
        printf("vnode_fd = %d\n", vnode_fd);

    EV_SET(&kev, vnode_fd, EVFILT_VNODE, EV_ADD, NOTE_DELETE, 0, &sockfd[0]);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    // XXX-causes an event..
    close(vnode_fd);

    success(test_id);
}

void
test_kevent_vnode_get(void)
{
    const char *test_id = "kevent(EVFILT_VNODE, get)";
    struct kevent kev;
    int nfds;

    test_begin(test_id);

    if (unlink("/tmp/kqueue-test.tmp") < 0)
        err(1, "unlink");

    nfds = kevent(kqfd, NULL, 0, &kev, 1, NULL);
    if (nfds < 1)
        err(1, "%s", test_id);
    if (kev.ident != vnode_fd ||
            kev.filter != EVFILT_VNODE || 
            kev.fflags != NOTE_DELETE)
        err(1, "%s - incorrect event (sig=%u; filt=%d; flags=%d)", 
                test_id, (unsigned int)kev.ident, kev.filter, kev.flags);

    success(test_id);
}

void
test_kevent_vnode_del(void)
{
    const char *test_id = "kevent(EVFILT_VNODE, EV_DELETE)";
    struct kevent kev;

    test_begin(test_id);

    EV_SET(&kev, vnode_fd, EVFILT_VNODE, EV_DELETE, 0, 0, &sockfd[0]);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    success(test_id);
}

int 
main(int argc, char **argv)
{
    int test_socket = 1;
    int test_signal = 0;//XXX-FIXME
    int test_vnode = 1;
    int test_timer = 1;

    while (argc) {
        if (strcmp(argv[0], "--no-socket") == 0)
            test_socket = 0;
        if (strcmp(argv[0], "--no-timer") == 0)
            test_timer = 0;
        if (strcmp(argv[0], "--no-signal") == 0)
            test_signal = 0;
        if (strcmp(argv[0], "--no-vnode") == 0)
            test_vnode = 0;
        argv++;
        argc--;
    }

    /* Create a connected pair of full-duplex sockets for testing socket events */
    if (socketpair(AF_LOCAL, SOCK_STREAM, 0, sockfd) < 0) 
        abort();

    test_kqueue();

    if (test_socket) {
        test_kevent_socket_add();
        test_kevent_socket_get();
        test_kevent_socket_disable();
        test_kevent_socket_enable();
        test_kevent_socket_del();
        test_kevent_socket_eof();
    }

    if (test_signal) {
        test_kevent_signal_add();
        test_kevent_signal_get();
        test_kevent_signal_disable();
        test_kevent_signal_enable();
        test_kevent_signal_del();
    }

    if (test_vnode) {
        test_kevent_vnode_add();
#if ! FIXME
        //broken, hangs on epoll of kq->pfd
        test_kevent_vnode_get();
#endif
        test_kevent_vnode_del();
    }

    if (test_timer) {
    }

    test_kqueue_close();

    puts("all tests completed.");
    return (0);
}

#else     /* UNIT_TEST */

void __kqueue_dummy(void)
{
    /* STUB */
}

#endif    /* ! UNIT_TEST */
