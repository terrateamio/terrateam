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

#include "private.h"

struct map {
    volatile size_t len;
    void **data;
};

struct map *
map_new(size_t len)
{
    struct map *dst;

    dst = calloc(1, sizeof(*dst));
    if (dst == NULL)
        return (NULL);
    dst->data = mmap(NULL, len * sizeof(void *), PROT_READ | PROT_WRITE, 
            MAP_PRIVATE | MAP_NORESERVE | MAP_ANON, -1, 0);
    if (dst->data == MAP_FAILED) {
        dbg_perror("mmap(2)");
        free(dst);
        return (NULL);
    }
    dst->len = len;

    return (dst);
}

int
map_insert(struct map *m, int idx, void *ptr)
{
    if (slowpath(idx < 0 || idx > m->len))
           return (-1);

    if (__sync_val_compare_and_swap(&(m->data[idx]), 0, ptr) == NULL) {
        dbg_printf("inserted %p in location %d", ptr, idx);
        return (0);
    } else {
        dbg_printf("tried to insert a value into a non-empty location %d (value=%p)",
                idx,
                m->data[idx]);
        return (-1);
    }
}

void *
map_lookup(struct map *m, int idx)
{
    if (slowpath(idx < 0 || idx > m->len))
        return (NULL);

    return m->data[idx];
}

int
map_delete(struct map *m, int idx)
{
    if (slowpath(idx < 0 || idx > m->len))
        return (-1);

    //TODO: use CAS and fail if entry is NULL

    m->data[idx] = NULL;
    return (0);
}
