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

/* A structure is used to allow other targets to emulate this */
struct eventfd {
    int fd;
};

struct eventfd *
eventfd_create(void)
{
    struct eventfd *e;
    int evfd;

    e = malloc(sizeof(*e));
    if (e == NULL)
        return (NULL);

    if ((evfd = eventfd(0, 0)) < 0) {
        free(e);
        return (NULL);
    }
    if (fcntl(evfd, F_SETFL, O_NONBLOCK) < 0) {
        free(e);
        close(evfd);
        return (NULL);
    }
    e->fd = evfd;

    return (e);
}

void
eventfd_free(struct eventfd *e)
{
    close(e->fd);
    free(e);
}

int
eventfd_raise(struct eventfd *e)
{
    uint64_t counter;
    int rv = 0;

    dbg_puts("raising event level");
    counter = 1;
    if (write(e->fd, &counter, sizeof(counter)) < 0) {
        switch (errno) {
            case EAGAIN:    
                /* Not considered an error */
                break;

            case EINTR:
                rv = -EINTR;
                break;

            default:
                dbg_printf("write(2): %s", strerror(errno));
                rv = -1;
        }
    }
    return (rv);
}

int
eventfd_lower(struct eventfd *e)
{
    uint64_t cur;
    int rv = 0;

    /* Reset the counter */
    dbg_puts("lowering event level");
    if (read(e->fd, &cur, sizeof(cur)) < sizeof(cur)) {
        switch (errno) {
            case EAGAIN:    
                /* Not considered an error */
                break;

            case EINTR:
                rv = -EINTR;
                break;

            default:
                dbg_printf("read(2): %s", strerror(errno));
                rv = -1;
        }
    } 

    return (rv);
}

int
eventfd_reader(struct eventfd *e)
{
    return (e->fd);
}

int
eventfd_writer(struct eventfd *e)
{
    return (e->fd);
}
