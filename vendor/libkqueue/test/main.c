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

#include "common.h"

char *cur_test_id = "undef";
int kqfd;

extern void test_evfilt_read();

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
        puts("\nUnexpected event:");
        puts(kevent_to_str(&kev));
        errx(1, "%d event(s) pending, but none expected:", nfds);
    }
}

/* Copied from ../kevent.c kevent_dump() */
const char *
kevent_to_str(struct kevent *kev)
{
    char buf[512];
    snprintf(&buf[0], sizeof(buf), "[filter=%d,flags=%d,ident=%u,udata=%p]",
            kev->filter,
            kev->flags,
            (u_int) kev->ident,
            kev->udata);
    return (strdup(buf));
}

void
kevent_cmp(struct kevent *k1, struct kevent *k2)
{
    if (memcmp(k1, k2, sizeof(*k1)) != 0) {
        printf("kevent_cmp: mismatch: %s != %s\n", 
              kevent_to_str(k1), kevent_to_str(k2));
        abort();
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
#if LIBKQUEUE
    kqueue_free(kqfd);
#endif
    success("kqueue_close()");
}

int 
main(int argc, char **argv)
{
    int test_socket = 1;
    int test_signal = 1;//XXX-FIXME
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

    test_kqueue();

    if (test_socket) {
        test_evfilt_read();
    }

#if TODO
    if (test_signal) {
        test_kevent_signal_add();
        test_kevent_signal_get();
        test_kevent_signal_disable();
        test_kevent_signal_enable();
        test_kevent_signal_del();
        test_kevent_signal_oneshot();
    }

    if (test_vnode) {
        test_kevent_vnode_add();
        test_kevent_vnode_del();
        test_kevent_vnode_disable_and_enable();
        test_kevent_vnode_dispatch();
        test_kevent_vnode_note_write();
        test_kevent_vnode_note_attrib();
        test_kevent_vnode_note_rename();
        test_kevent_vnode_note_delete();
    }

    if (test_timer) {
        test_kevent_timer_add();
        test_kevent_timer_del();
        test_kevent_timer_get();
    }
#endif

    test_kqueue_close();

    puts("all tests completed.");
    return (0);
}
