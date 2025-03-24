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

#ifndef _COMMON_H
#define _COMMON_H

#if HAVE_ERR_H
# include <err.h>
#else
# define err(rc, fmt, ...) do { \
    char buf[128]; \
    snprintf(buf, sizeof(buf), fmt, ##__VA_ARGS__);\
    perror(buf); \
    exit(rc); \
} while (0)

# define errx(rc, msg, ...) do { \
    fprintf(stderr, msg"\n", ##__VA_ARGS__);\
    exit(rc); \
} while (0)
#endif

#define die(fmt, ...)   do { \
    fprintf(stderr, "%s(): "fmt": %s (%i)\n", __func__, ##__VA_ARGS__, strerror(errno), errno);\
    abort();\
} while (0)

#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>

#if !defined(__APPLE__) && !defined(__FreeBSD__)
#  include "config.h"
#endif

#if defined(__FreeBSD__)
#  include <netinet/in.h>
#endif

#ifndef _WIN32
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/event.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <poll.h>
#include <netdb.h>
#else
#  include "include/sys/event.h"
#  include "src/windows/platform.h"
#endif

#include "config.h"

/** Convenience macros
 *
 */
#define NUM_ELEMENTS(_t) (sizeof((_t)) / sizeof(*(_t)))

struct test_context;

struct unit_test {
    const char   *ut_name;
    int          ut_enabled;
    void         (*ut_func)(struct test_context *);
    int          ut_start;
    int          ut_end;
    unsigned int ut_num;
};

#define MAX_TESTS 50
struct test_context {
    struct unit_test tests[MAX_TESTS];
    struct unit_test *test; /* Current test being run */

    char *cur_test_id;
    int iterations;
    int iteration;
    int kqfd;

    /* EVFILT_READ and EVFILT_WRITE */
    int client_fd;
    int server_fd;
    int listen_fd;

    /* EVFILT_VNODE */
    int vnode_fd;
    char testfile[1024];
};

void test_kqueue(struct test_context *);
void test_evfilt_read(struct test_context *);
void test_evfilt_signal(struct test_context *);
void test_evfilt_vnode(struct test_context *);
void test_evfilt_timer(struct test_context *);
void test_evfilt_proc(struct test_context *);
#ifdef EVFILT_USER
void test_evfilt_user(struct test_context *);
#endif
void test_evfilt_libkqueue(struct test_context *);

#define test(f, ctx ,...) do {                                            \
    if ((ctx->test->ut_num >= ctx->test->ut_start) && (ctx->test->ut_num <= ctx->test->ut_end)) {\
        assert(ctx != NULL); \
        test_begin(ctx, "test_"#f"()\t"__VA_ARGS__); \
        errno = 0; \
        test_##f(ctx); \
        test_end(ctx); \
    } \
    ctx->test->ut_num++; \
} while (/*CONSTCOND*/0)

extern const char * kevent_to_str(struct kevent *);
void kevent_get(struct kevent kev[], int numevents, int kqfd, int expect_rv);
void kevent_get_hires(struct kevent kev[], int numevents, int kqfd, struct timespec *timeout);
int kevent_get_timeout(struct kevent kev[], int numevents, int kqfd, struct timespec *timeout);

void kevent_update(int kqfd, struct kevent *kev);
void kevent_update_expect_fail(int kqfd, struct kevent *kev);

#define kevent_cmp(a,b) _kevent_cmp(a,b, __FILE__, __LINE__)
void _kevent_cmp(struct kevent *expected, struct kevent *got, const char *file, int line);

#define kevent_rv_cmp(a,b) _kevent_rv_cmp(a,b, __FILE__, __LINE__)
void _kevent_rv_cmp(int expected, int got, const char *file, int line);

void
kevent_add(int kqfd, struct kevent *kev,
        uintptr_t ident,
        short     filter,
        u_short   flags,
        u_int     fflags,
        intptr_t  data,
        void      *udata);


#define kevent_add_with_receipt(...) _kevent_add_with_receipt(__VA_ARGS__, __FILE__, __LINE__)
void
_kevent_add_with_receipt(int kqfd, struct kevent *kev,
        uintptr_t ident,
        short     filter,
        u_short   flags,
        u_int     fflags,
        intptr_t  data,
        void      *udata,
        char const *file,
        int line);

/* Checks if any events are pending, which is an error. */
#define test_no_kevents(_kq) _test_no_kevents(_kq, __FILE__, __LINE__)
void _test_no_kevents(int, const char *, int);

unsigned int print_fd_table(void);
unsigned int get_fd_limit(void);

/* From test.c */
void    test_begin(struct test_context *, const char *);
void    test_end(struct test_context *);
void    test_atexit(void);
void    testing_begin(void);
void    testing_end(void);
void    testing_end_quiet(void);
int     testing_make_uid(void);

#endif  /* _COMMON_H */
