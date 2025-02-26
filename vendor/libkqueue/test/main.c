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

#include <limits.h>

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
        if (test->ut_enabled) {
            ctx->test = test; /* Record the current test */
            test->ut_func(ctx);
        }
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
           " testclass[:<num>|:<start>-<end>] Tests suites to run:\n"
           "           ["
           "kqueue "
           "socket "
           "signal "
           "proc "
           "timer "
           "vnode "
           "user "
           "libkqueue]\n"
           "           All tests are run by default\n"
           "\n"
          );
    exit(1);
}

int
main(int argc, char **argv)
{
    struct unit_test tests[MAX_TESTS] = {
        { .ut_name = "kqueue",
          .ut_enabled = 1,
          .ut_func = test_kqueue,
          .ut_end = INT_MAX },

        { .ut_name = "socket",
          .ut_enabled = 1,
          .ut_func = test_evfilt_read,
          .ut_end = INT_MAX },
#if !defined(_WIN32) && !defined(__ANDROID__)
        // XXX-FIXME -- BROKEN ON LINUX WHEN RUN IN A SEPARATE THREAD
        { .ut_name = "signal",
          .ut_enabled = 1,
          .ut_func = test_evfilt_signal,
          .ut_end = INT_MAX },
#endif
        { .ut_name = "proc",
          .ut_enabled = 1,
          .ut_func = test_evfilt_proc,
          .ut_end = INT_MAX },
        { .ut_name = "timer",
          .ut_enabled = 1,
          .ut_func = test_evfilt_timer,
          .ut_end = INT_MAX },
#ifndef _WIN32
        { .ut_name = "vnode",
          .ut_enabled = 1,
          .ut_func = test_evfilt_vnode,
          .ut_end = INT_MAX },
#endif
#ifdef EVFILT_USER
        { .ut_name = "user",
          .ut_enabled = 1,
          .ut_func = test_evfilt_user,
          .ut_end = INT_MAX },
#endif
#ifdef EVFILT_LIBKQUEUE
        { .ut_name = "libkqueue",
          .ut_enabled = 1,
          .ut_func = test_evfilt_libkqueue,
          .ut_end = INT_MAX },
        { NULL, 0, NULL },
#endif
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
            size_t namelen = strlen(test->ut_name);
            char const *p;
            char *q;

            if (strncmp(arg, test->ut_name, strlen(test->ut_name)) == 0) {
                test->ut_enabled = 1;
                match = 1;

                p = arg + namelen;

                /*
                 * Test name includes a test range
                 */
                if (*p == ':') {
                    p++;

                    test->ut_start = strtoul(p, &q, 10);
                    if (p == q)
                        goto invalid_option;
                    p = q;

                    /*
                     * Range is in the format <start>-<end>
                     */
                    if (*p == '-') {
                        p++;
                        test->ut_end = strtoul(p, &q, 10);
                        if (p == q)
                            goto invalid_option;
                        printf("enabled test: %s (%u-%u)\n", test->ut_name, test->ut_start, test->ut_end);
                    /*
                     * Range is in the format <num>
                     */
                    } else if (*p == '\0') {
                        test->ut_end = test->ut_start;
                        printf("enabled test: %s (%u)\n", test->ut_name, test->ut_start);
                    /*
                     * Range is invalid
                     */
                    } else
                        goto invalid_option;
                /*
                 * Test name does not include a range
                 */
                } else if (*p == '\0') {
                    test->ut_start = 0;
                    test->ut_end = INT_MAX;
                    printf("enabled test: %s\n", test->ut_name);
                } else
                    goto invalid_option;
                break;
            }
        }
        if (!match) {
        invalid_option:
            printf("ERROR: invalid option: %s\n", arg);
            exit(1);
        }
    }
#endif

    test_harness(tests, iterations);

    return (0);
}
