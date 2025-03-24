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

static int sigusr1_caught = 0;
static pid_t pid;

static void
sig_handler(int signum)
{
    sigusr1_caught = 1;
}

static void
test_kevent_proc_add(struct test_context *ctx)
{
    struct kevent kev;

    test_no_kevents(ctx->kqfd);
    kevent_add(ctx->kqfd, &kev, pid, EVFILT_PROC, EV_ADD, NOTE_EXIT, 0, NULL);
    test_no_kevents(ctx->kqfd);
}

static void
test_kevent_proc_delete(struct test_context *ctx)
{
    struct kevent kev;

    test_no_kevents(ctx->kqfd);
    kevent_add(ctx->kqfd, &kev, pid, EVFILT_PROC, EV_DELETE, NOTE_EXIT, 0, NULL);
    if (kill(pid, SIGKILL) < 0)
        die("kill");
    sleep(1);
    test_no_kevents(ctx->kqfd);
}

static void
test_kevent_proc_get(struct test_context *ctx)
{
    struct kevent kev, buf[2];
    int fflags;

    /*
     *  macOS requires NOTE_EXITSTATUS to get the
     *  exit code of the process, FreeBSD always
     *  provides it.
     */
#ifdef __APPLE__
    fflags = NOTE_EXIT | NOTE_EXITSTATUS;
#else
    fflags = NOTE_EXIT;
#endif

    /* Create a child that waits to be killed and then exits */
    pid = fork();
    if (pid == 0) {
        pause();
        printf(" -- child caught signal, exiting\n");
        testing_end_quiet();
        exit(0);
    }
    printf(" -- child created (pid %d)\n", (int) pid);

    test_no_kevents(ctx->kqfd);
    kevent_add(ctx->kqfd, &kev, pid, EVFILT_PROC, EV_ADD, fflags, 0, NULL);

    /* Cause the child to exit, then retrieve the event */
    printf(" -- killing process %d\n", (int) pid);
    if (kill(pid, SIGKILL) < 0)
        die("kill");
    kevent_get(buf, NUM_ELEMENTS(buf), ctx->kqfd, 1);

    kev.data = SIGKILL; /* What we expected the process exit code to be */
    kev.flags = EV_ADD | EV_ONESHOT | EV_CLEAR | EV_EOF;

    kevent_cmp(&kev, buf);
    test_no_kevents(ctx->kqfd);
}

static void
test_kevent_proc_exit_status_ok(struct test_context *ctx)
{
    struct kevent kev, buf[2];
    int fflags;

    /*
     *  macOS requires NOTE_EXITSTATUS to get the
     *  exit code of the process, FreeBSD always
     *  provides it.
     */
#ifdef __APPLE__
    fflags = NOTE_EXIT | NOTE_EXITSTATUS;
#else
    fflags = NOTE_EXIT;
#endif

    /* Create a child that waits to be killed and then exits */
    pid = fork();
    if (pid == 0) {
        usleep(100000);
        printf(" -- child done sleeping, exiting (0)\n");
        testing_end_quiet();
        exit(0);
    }
    printf(" -- child created (pid %d)\n", (int) pid);

    test_no_kevents(ctx->kqfd);
    kevent_add(ctx->kqfd, &kev, pid, EVFILT_PROC, EV_ADD, fflags, 0, NULL);

    kevent_get(buf, NUM_ELEMENTS(buf), ctx->kqfd, 1);

    kev.data = 0; /* What we expected the process exit code to be */
    kev.flags = EV_ADD | EV_ONESHOT | EV_CLEAR | EV_EOF;

    kevent_cmp(&kev, buf);
    test_no_kevents(ctx->kqfd);
}

static void
test_kevent_proc_exit_status_error(struct test_context *ctx)
{
    struct kevent kev, buf[2];
    int fflags;

    /*
     *  macOS requires NOTE_EXITSTATUS to get the
     *  exit code of the process, FreeBSD always
     *  provides it.
     */
#ifdef __APPLE__
    fflags = NOTE_EXIT | NOTE_EXITSTATUS;
#else
    fflags = NOTE_EXIT;
#endif

    /* Create a child that waits to be killed and then exits */
    pid = fork();
    if (pid == 0) {
        usleep(100000);
        printf(" -- child done sleeping, exiting (64)\n");
        testing_end_quiet();
        exit(64);
    }
    printf(" -- child created (pid %d)\n", (int) pid);

    test_no_kevents(ctx->kqfd);
    kevent_add(ctx->kqfd, &kev, pid, EVFILT_PROC, EV_ADD, fflags, 0, NULL);

    kevent_get(buf, NUM_ELEMENTS(buf), ctx->kqfd, 1);

    kev.data = 64 << 8; /* What we expected the process exit code to be */
    kev.flags = EV_ADD | EV_ONESHOT | EV_CLEAR | EV_EOF;

    kevent_cmp(&kev, buf);
    test_no_kevents(ctx->kqfd);
}

static void
test_kevent_proc_multiple_kqueue(struct test_context *ctx)
{
    struct kevent kev, buf_a[2], buf_b[2];
    int fflags;
    int kq_b;

    /*
     *  macOS requires NOTE_EXITSTATUS to get the
     *  exit code of the process, FreeBSD always
     *  provides it.
     */
#ifdef __APPLE__
    fflags = NOTE_EXIT | NOTE_EXITSTATUS;
#else
    fflags = NOTE_EXIT;
#endif

    kq_b = kqueue();
    if (kq_b < 0)
        die("kqueue");

    /* Create a child that waits to be killed and then exits */
    pid = fork();
    if (pid == 0) {
        usleep(100000);
        printf(" -- child done sleeping, exiting (64)\n");
        testing_end_quiet();
        exit(64);
    }
    printf(" -- child created (pid %d)\n", (int) pid);

    test_no_kevents(ctx->kqfd);
    test_no_kevents(kq_b);

    kevent_add(ctx->kqfd, &kev, pid, EVFILT_PROC, EV_ADD, fflags, 0, NULL);
    kevent_add(kq_b, &kev, pid, EVFILT_PROC, EV_ADD, fflags, 0, NULL);

    kevent_get(buf_a, NUM_ELEMENTS(buf_a), ctx->kqfd, 1);
    kevent_get(buf_b, NUM_ELEMENTS(buf_b), kq_b, 1);

    kev.data = 64 << 8; /* What we expected the process exit code to be */
    kev.flags = EV_ADD | EV_ONESHOT | EV_CLEAR | EV_EOF;

    kevent_cmp(&kev, buf_a);
    kevent_cmp(&kev, buf_b);
    test_no_kevents(ctx->kqfd);
    test_no_kevents(kq_b);

    close(kq_b);
}

#ifdef TODO
void
test_kevent_signal_disable(struct test_context *ctx)
{
    const char *test_id = "kevent(EVFILT_SIGNAL, EV_DISABLE)";
    struct kevent kev;

    test_begin(test_id);

    EV_SET(&kev, SIGUSR1, EVFILT_SIGNAL, EV_DISABLE, 0, 0, NULL);
    kevent_rv_cmp(0, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));

    /* Block SIGUSR1, then send it to ourselves */
    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, SIGKILL);
    if (sigprocmask(SIG_BLOCK, &mask, NULL) == -1)
        die("sigprocmask");
    if (kill(getpid(), SIGKILL) < 0)
        die("kill");

    test_no_kevents();

    success();
}

void
test_kevent_signal_enable(struct test_context *ctx)
{
    const char *test_id = "kevent(EVFILT_SIGNAL, EV_ENABLE)";
    struct kevent kev, buf;

    test_begin(test_id);

    EV_SET(&kev, SIGUSR1, EVFILT_SIGNAL, EV_ENABLE, 0, 0, NULL);
    kevent_rv_cmp(0, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));

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
    kevent_get(buf, NUM_ELEMENTS(buf), ctx->kqfd, 1)
    kevent_cmp(&kev, &buf);

    /* Delete the watch */
    kev.flags = EV_DELETE;
    kevent_rv_cmp(0, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));

    success();
}

void
test_kevent_signal_del(struct test_context *ctx)
{
    const char *test_id = "kevent(EVFILT_SIGNAL, EV_DELETE)";
    struct kevent kev;

    test_begin(test_id);

    /* Delete the kevent */
    EV_SET(&kev, SIGUSR1, EVFILT_SIGNAL, EV_DELETE, 0, 0, NULL);
    kevent_rv_cmp(0, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));

    /* Block SIGUSR1, then send it to ourselves */
    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, SIGUSR1);
    if (sigprocmask(SIG_BLOCK, &mask, NULL) == -1)
        die("sigprocmask");
    if (kill(getpid(), SIGUSR1) < 0)
        die("kill");

    test_no_kevents();
    success();
}

void
test_kevent_signal_oneshot(struct test_context *ctx)
{
    const char *test_id = "kevent(EVFILT_SIGNAL, EV_ONESHOT)";
    struct kevent kev, buf;

    test_begin(test_id);

    EV_SET(&kev, SIGUSR1, EVFILT_SIGNAL, EV_ADD | EV_ONESHOT, 0, 0, NULL);
    kevent_rv_cmp(0, kevent(ctx->kqfd, &kev, 1, NULL, 0, NULL));

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
    kevent_get(buf, NUM_ELEMENTS(buf), ctx->kqfd, 1)
    kevent_cmp(&kev, &buf);

    /* Send another one and make sure we get no events */
    if (kill(getpid(), SIGUSR1) < 0)
        die("kill");
    test_no_kevents();

    success();
}
#endif

void
test_evfilt_proc(struct test_context *ctx)
{
    signal(SIGUSR1, sig_handler);

    /* Create a child that waits to be killed and then exits */
    pid = fork();
    if (pid == 0) {
        pause();
        testing_end_quiet();
        exit(2);
    }
    printf(" -- child created (pid %d)\n", (int) pid);

    test(kevent_proc_add, ctx);
    test(kevent_proc_delete, ctx);
    test(kevent_proc_get, ctx);
    test(kevent_proc_exit_status_ok, ctx);
    test(kevent_proc_exit_status_error, ctx);
    test(kevent_proc_multiple_kqueue, ctx);

    signal(SIGUSR1, SIG_DFL);

#if TODO
    test_kevent_signal_add();
    test_kevent_signal_del();
    test_kevent_signal_get();
    test_kevent_signal_disable();
    test_kevent_signal_enable();
    test_kevent_signal_oneshot();
#endif
}
