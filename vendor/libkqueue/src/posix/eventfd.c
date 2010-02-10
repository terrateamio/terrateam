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
#include <sys/socket.h>
#include <unistd.h>

#include "private.h"

struct eventfd {
    int fd[2];
};

struct eventfd *
eventfd_create(void)
{
    struct eventfd *e;
    int evfd;

    e = malloc(sizeof(*e));
    if (e == NULL)
        return (NULL);

    if (socketpair(AF_UNIX, SOCK_STREAM, 0, e->fd) < 0)
        free(e);
        return (NULL);
    }
    if ((fcntl(e->fd[0], F_SETFL, O_NONBLOCK) < 0) ||
            (fcntl(e->fd[1], F_SETFL, O_NONBLOCK) < 0)) {
        free(e);
        close(e->fd[0]);
        close(e->fd[1]);
        close(evfd);
        return (NULL);
    }

    return (e);
}

void
eventfd_free(struct eventfd *e)
{
    close(e->fd[0]);
    close(e->fd[1]);
    free(e);
}

int
eventfd_raise(struct eventfd *e)
{
    dbg_puts("raising event level");
    if (write(e->fd[0], ".", 1) < 0) {
        /* FIXME: handle EAGAIN and EINTR */
        dbg_printf("write(2): %s", strerror(errno));
        return (-1);
    }
    return (0);
}

int
eventfd_lower(struct eventfd *e)
{
    char buf[1024];

    /* Reset the counter */
    dbg_puts("lowering event level");
    if (read(e->fd[1], &buf, sizeof(buf)) < 0) {
        /* FIXME: handle EAGAIN and EINTR */
        /* FIXME: loop so as to consume all data.. may need mutex */
        dbg_printf("read(2): %s", strerror(errno));
        return (-1);
    }
    return (0);
}

int
eventfd_reader(struct eventfd *e)
{
    return (e->fd[1]);
}

int
eventfd_writer(struct eventfd *e)
{
    return (e->fd[0]);
}
