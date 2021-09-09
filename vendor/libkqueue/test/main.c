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

#if defined(__linux__) || defined(__FreeBSD__)
#include <sys/time.h>
#include <sys/resource.h>
#endif

#if defined(__linux__)
#include <sys/syscall.h>
#endif

#include "common.h"

unsigned int
get_fd_limit(void)
{
#ifdef _WIN32
    /* actually windows should be able to hold
       way more, as they use HANDLEs for everything.
       Still this number should still be sufficient for
       the provided number of kqueue fds.
       */
    return 65536;
#else
    struct rlimit rlim;

    if (getrlimit(RLIMIT_NOFILE, &rlim) < 0) {
        perror("getrlimit(2)");
        return (65536);
    } else {
        return (rlim.rlim_max);
    }
#endif
}

unsigned int
print_fd_table(void)
{
    unsigned int fd_max = get_fd_limit();
    unsigned int i;
    unsigned int used = 0;
    int our_errno = errno; /* Preserve errno */

#ifdef __linux__
    for (i = 0; i < fd_max; i++) {
        if (fcntl(i, F_GETFD) == 0) {
            printf("fd=%i used\n", i);
            used++;
        }
    }
#endif

    errno = our_errno;

    return used;
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

    if ((kqfd = kqueue()) < 0)
        die("kqueue()");
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
           " testclass Tests suites to run: ["
           "kqueue "
           "socket "
           "signal "
           "proc "
           "timer "
           "vnode "
           "user]\n"
           "           All tests are run by default\n"
           "\n"
          );
    exit(1);
}

int
main(int argc, char **argv)
{
    struct unit_test tests[MAX_TESTS] = {
        { "kqueue", 1, test_kqueue },

        { "socket", 1, test_evfilt_read },
#if !defined(_WIN32) && !defined(__ANDROID__)
        // XXX-FIXME -- BROKEN ON LINUX WHEN RUN IN A SEPARATE THREAD
        { "signal", 1, test_evfilt_signal },
#endif
        { "proc", 1, test_evfilt_proc },
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
