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

int kqfd;
int vnode_fd;

void
test_kevent_vnode_add(void)
{
    const char *testfile = "/tmp/kqueue-test.tmp";
    struct kevent kev;

    system("touch /tmp/kqueue-test.tmp");
    vnode_fd = open(testfile, O_RDONLY);
    if (vnode_fd < 0)
        err(1, "open of %s", testfile);
    else
        printf("vnode_fd = %d\n", vnode_fd);

    EV_SET(&kev, vnode_fd, EVFILT_VNODE, EV_ADD, 
            NOTE_WRITE | NOTE_ATTRIB | NOTE_RENAME | NOTE_DELETE, 0, NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);
}

void
test_kevent_vnode_note_delete(void)
{
    struct kevent kev;

    EV_SET(&kev, vnode_fd, EVFILT_VNODE, EV_ADD | EV_ONESHOT, NOTE_DELETE, 0, NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    if (unlink("/tmp/kqueue-test.tmp") < 0)
        err(1, "unlink");

    kevent_cmp(&kev, kevent_get(kqfd));
}

void
test_kevent_vnode_note_write(void)
{
    struct kevent kev;

    EV_SET(&kev, vnode_fd, EVFILT_VNODE, EV_ADD | EV_ONESHOT, NOTE_WRITE, 0, NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    if (system("echo hello >> /tmp/kqueue-test.tmp") < 0)
        err(1, "system");

    /* BSD kqueue adds NOTE_EXTEND even though it was not requested */
    /* BSD kqueue removes EV_ENABLE */
    kev.flags &= ~EV_ENABLE; // XXX-FIXME compatibility issue
    kev.fflags |= NOTE_EXTEND; // XXX-FIXME compatibility issue
    kevent_cmp(&kev, kevent_get(kqfd));
}

void
test_kevent_vnode_note_attrib(void)
{
    struct kevent kev;
    int nfds;

    EV_SET(&kev, vnode_fd, EVFILT_VNODE, EV_ADD | EV_ONESHOT, NOTE_ATTRIB, 0, NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    if (system("touch /tmp/kqueue-test.tmp") < 0)
        err(1, "system");

    nfds = kevent(kqfd, NULL, 0, &kev, 1, NULL);
    if (nfds < 1)
        err(1, "%s", test_id);
    if (kev.ident != vnode_fd ||
            kev.filter != EVFILT_VNODE || 
            kev.fflags != NOTE_ATTRIB)
        err(1, "%s - incorrect event (sig=%u; filt=%d; flags=%d)", 
                test_id, (unsigned int)kev.ident, kev.filter, kev.flags);
}

void
test_kevent_vnode_note_rename(void)
{
    struct kevent kev;
    int nfds;

    EV_SET(&kev, vnode_fd, EVFILT_VNODE, EV_ADD | EV_ONESHOT, NOTE_RENAME, 0, NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    if (system("mv /tmp/kqueue-test.tmp /tmp/kqueue-test2.tmp") < 0)
        err(1, "system");

    nfds = kevent(kqfd, NULL, 0, &kev, 1, NULL);
    if (nfds < 1)
        err(1, "%s", test_id);
    if (kev.ident != vnode_fd ||
            kev.filter != EVFILT_VNODE || 
            kev.fflags != NOTE_RENAME)
        err(1, "%s - incorrect event (sig=%u; filt=%d; flags=%d)", 
                test_id, (unsigned int)kev.ident, kev.filter, kev.flags);

    if (system("mv /tmp/kqueue-test2.tmp /tmp/kqueue-test.tmp") < 0)
        err(1, "system");
}

void
test_kevent_vnode_del(void)
{
    struct kevent kev;

    EV_SET(&kev, vnode_fd, EVFILT_VNODE, EV_DELETE, 0, 0, NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);
}

void
test_kevent_vnode_disable_and_enable(void)
{
    struct kevent kev;
    int nfds;

    test_no_kevents();

    /* Add the watch and immediately disable it */
    EV_SET(&kev, vnode_fd, EVFILT_VNODE, EV_ADD | EV_ONESHOT, NOTE_ATTRIB, 0, NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);
    kev.flags = EV_DISABLE;
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    /* Confirm that the watch is disabled */
    if (system("touch /tmp/kqueue-test.tmp") < 0)
        err(1, "system");
    test_no_kevents();

    /* Re-enable and check again */
    kev.flags = EV_ENABLE;
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);
    if (system("touch /tmp/kqueue-test.tmp") < 0)
        err(1, "system");
    nfds = kevent(kqfd, NULL, 0, &kev, 1, NULL);
    if (nfds < 1)
        err(1, "%s", test_id);
    if (kev.ident != vnode_fd ||
            kev.filter != EVFILT_VNODE || 
            kev.fflags != NOTE_ATTRIB)
        err(1, "%s - incorrect event (sig=%u; filt=%d; flags=%d)", 
                test_id, (unsigned int)kev.ident, kev.filter, kev.flags);
}

#if HAVE_EV_DISPATCH
void
test_kevent_vnode_dispatch(void)
{
    struct kevent kev;
    int nfds;

    test_no_kevents();

    EV_SET(&kev, vnode_fd, EVFILT_VNODE, EV_ADD | EV_DISPATCH, NOTE_ATTRIB, 0, NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "%s", test_id);

    if (system("touch /tmp/kqueue-test.tmp") < 0)
        err(1, "system");

    nfds = kevent(kqfd, NULL, 0, &kev, 1, NULL);
    if (nfds < 1)
        err(1, "%s", test_id);
    if (kev.ident != vnode_fd ||
            kev.filter != EVFILT_VNODE || 
            kev.fflags != NOTE_ATTRIB)
        err(1, "%s - incorrect event (sig=%u; filt=%d; flags=%d)", 
                test_id, (unsigned int)kev.ident, kev.filter, kev.flags);

    /* Confirm that the watch is disabled automatically */
    puts("-- checking that watch is disabled");
    if (system("touch /tmp/kqueue-test.tmp") < 0)
        err(1, "system");
    test_no_kevents();

    /* Delete the watch */
    EV_SET(&kev, vnode_fd, EVFILT_VNODE, EV_DELETE, NOTE_ATTRIB, 0, NULL);
    if (kevent(kqfd, &kev, 1, NULL, 0, NULL) < 0)
        err(1, "remove watch failed: %s", test_id);
}
#endif 	/* HAVE_EV_DISPATCH */

void
test_evfilt_vnode()
{
	kqfd = kqueue();
    test(kevent_vnode_add);
    test(kevent_vnode_del);
    test(kevent_vnode_disable_and_enable);
#if HAVE_EV_DISPATCH
    test(kevent_vnode_dispatch);
#endif
    test(kevent_vnode_note_write);
    test(kevent_vnode_note_attrib);
    test(kevent_vnode_note_rename);
    test(kevent_vnode_note_delete);
	close(kqfd);
}
