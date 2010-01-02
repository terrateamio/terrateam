/*
 * Copyright (c) 2010 Mark Heily <mark@heily.com>
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

#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/eventfd.h>
#include <unistd.h>

#include "private.h"

/* TODO: make src/posix/eventfd.c equivalent functions */

int
eventfd_create(void)
{
    int evfd;

    if ((evfd = eventfd(0, 0)) < 0) 
        return (-1);
    if (fcntl(evfd, F_SETFL, O_NONBLOCK) < 0) {
        close(evfd);
        return (-1);
    }

    return (evfd);
}

int
eventfd_raise(int evfd)
{
    uint64_t counter;

    dbg_puts("efd_raise(): raising event level");
    counter = 1;
    if (write(evfd, &counter, sizeof(counter)) < 0) {
        /* FIXME: handle EAGAIN */
        dbg_printf("write(2): %s", strerror(errno));
        return (-1);
    }
    return (0);
}

static int
eventfd_lower(int evfd)
{
    uint64_t cur;

    /* Reset the counter */
    dbg_puts("efd_lower(): lowering event level");
    if (read(evfd, &cur, sizeof(cur)) < sizeof(cur)) {
        /* FIXME: handle EAGAIN */
        dbg_printf("read(2): %s", strerror(errno));
        return (-1);
    }
    dbg_printf("  counter=%llu", (unsigned long long) cur);
    return (0);
}


