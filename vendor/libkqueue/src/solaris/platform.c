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

int
solaris_kqueue_init(struct kqueue *kq)
{
    if (posix_kqueue_init(kq) < 0)
        return (-1);
    if ((kq->kq_port = port_create()) < 0) {
        dbg_perror("port_create(2)");
        return (-1);
    }
    dbg_printf("created event port; fd=%d", kq->kq_port);
    TAILQ_INIT(&kq->kq_events);
    return (0);
}

void
solaris_kqueue_free(struct kqueue *kq)
{
    posix_kqueue_free(kq);
    if (kq->kq_port > 0) {
        (void) close(kq->kq_port);
        dbg_printf("closed event port; fd=%d", kq->kq_port);
    }
}

const struct kqueue_vtable const kqops =
{
    solaris_kqueue_init,
    solaris_kqueue_free,
};
