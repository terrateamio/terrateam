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
# define err(rc,msg,...) do { perror(msg); exit(rc); } while (0)
# define errx(rc,msg,...) do { puts(msg); exit(rc); } while (0)
#endif

#define die(str)   do { \
    fprintf(stderr, "%s(): %s: %s\n", __func__,str, strerror(errno));\
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

#ifndef _WIN32
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/event.h>
#include <arpa/inet.h>
#include "config.h"
#else
#include "../include/sys/event.h"
#include "../src/windows/platform.h"
#pragma comment(lib, "../Debug/libkqueue.lib")
#endif


void test_evfilt_read(int);
void test_evfilt_signal(int);
void test_evfilt_vnode(int);
void test_evfilt_timer(int);
void test_evfilt_proc(int);
#if HAVE_EVFILT_USER
void test_evfilt_user(int);
#endif

#define test(f,...) do {                                             \
    test_begin("test_"#f"()\t"__VA_ARGS__);                                                  \
    test_##f();\
    test_end();                                                     \
} while (/*CONSTCOND*/0)

extern const char * kevent_to_str(struct kevent *);
struct kevent * kevent_get(int);


void kevent_update(int kqfd, struct kevent *kev);

void kevent_cmp(struct kevent *, struct kevent *);

void
kevent_add(int kqfd, struct kevent *kev, 
        uintptr_t ident,
        short     filter,
        u_short   flags,
        u_int     fflags,
        intptr_t  data,
        void      *udata);

/* DEPRECATED: */
#define KEV_CMP(kev,_ident,_filter,_flags) do {                 \
    if (kev.ident != (_ident) ||                                \
            kev.filter != (_filter) ||                          \
            kev.flags != (_flags)) \
        err(1, "kevent mismatch: got [%d,%d,%d] but expecting [%d,%d,%d]", \
                (int)_ident, (int)_filter, (int)_flags,\
                (int)kev.ident, kev.filter, kev.flags);\
} while (0);

/* Checks if any events are pending, which is an error. */
void test_no_kevents(int);

/* From test.c */
void    test_begin(const char *);
void    test_end(void);
void    test_atexit(void);
void    testing_begin(void);
void    testing_end(void);
int     testing_make_uid(void);

#endif  /* _COMMON_H */
