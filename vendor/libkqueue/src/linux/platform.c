/*
 * Copyright (c) 2011 Mark Heily <mark@heily.com>
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

#include "../common/private.h"

const struct kqueue_vtable kqops = {
    posix_kqueue_init,
    posix_kqueue_free,
	posix_kevent_wait,
	posix_kevent_copyout,
	NULL,
	NULL,
    linux_eventfd_init,
    linux_eventfd_close,
    linux_eventfd_raise,
    linux_eventfd_lower,
    linux_eventfd_descriptor
};

int
linux_eventfd_init(struct eventfd *e)
{
    int evfd;

    if ((evfd = eventfd(0, 0)) < 0) {
        dbg_perror("eventfd");
        return (-1);
    }
    if (fcntl(evfd, F_SETFL, O_NONBLOCK) < 0) {
        dbg_perror("fcntl");
        close(evfd);
        return (-1);
    }
    e->ef_id = evfd;

    return (0);
}

void
linux_eventfd_close(struct eventfd *e)
{
    close(e->ef_id);
    e->ef_id = -1;
}

int
linux_eventfd_raise(struct eventfd *e)
{
    uint64_t counter;
    int rv = 0;

    dbg_puts("raising event level");
    counter = 1;
    if (write(e->ef_id, &counter, sizeof(counter)) < 0) {
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
linux_eventfd_lower(struct eventfd *e)
{
    uint64_t cur;
    int rv = 0;

    /* Reset the counter */
    dbg_puts("lowering event level");
    if (read(e->ef_id, &cur, sizeof(cur)) < sizeof(cur)) {
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
linux_eventfd_descriptor(struct eventfd *e)
{
    return (e->ef_id);
}
