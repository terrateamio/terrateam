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

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <string.h>

#include "private.h"

int DEBUG_ACTIVE = 0;
char *DEBUG_IDENT = "KQ";

static unsigned int
get_fd_limit(void)
{
#ifdef _WIN32
    /* actually windows should be able to hold
       way more, as they use HANDLEs for everything.
       Still this number should still be sufficient for
       the provided number of kqueue fds.
       */
    return 65536;
#else
    struct rlimit rlim;
    
    if (getrlimit(RLIMIT_NOFILE, &rlim) < 0) {
        dbg_perror("getrlimit(2)");
        return (65536);
    } else {
        return (rlim.rlim_max);
    }
#endif
}

static struct map *kqmap;

int CONSTRUCTOR
libkqueue_init(void)
{
#ifdef NDEBUG
    DEBUG_ACTIVE = 0;
#elif _WIN32
	/* Experimental port, always debug */
	DEBUG_ACTIVE = 1;
# ifndef __GNUC__
	/* Enable heap surveillance */
	{
		int tmpFlag = _CrtSetDbgFlag( _CRTDBG_REPORT_FLAG );
		tmpFlag |= _CRTDBG_CHECK_ALWAYS_DF;
		_CrtSetDbgFlag(tmpFlag);
	}
# endif
#else
    char *s = getenv("KQUEUE_DEBUG");
    if (s != NULL && strlen(s) > 0)
        DEBUG_ACTIVE = 1;
#endif

   kqmap = map_new(get_fd_limit()); // INT_MAX
   if (kqmap == NULL)
       abort(); 
   if (knote_init() < 0)
       abort();
   dbg_puts("library initialization complete");
   return (0);
}

#if DEADWOOD
static int
kqueue_cmp(struct kqueue *a, struct kqueue *b)
{
    return memcmp(&a->kq_id, &b->kq_id, sizeof(int)); 
}

/* Must hold the kqtree_mtx when calling this */
void
kqueue_free(struct kqueue *kq)
{
    RB_REMOVE(kqt, &kqtree, kq);
    filter_unregister_all(kq);
    kqops.kqueue_free(kq);
    free(kq);
}

#endif

struct kqueue *
kqueue_lookup(int kq)
{
    return ((struct kqueue *) map_lookup(kqmap, kq));
}

int VISIBLE
kqueue(void)
{
	struct kqueue *kq;
    struct kqueue *tmp;

    kq = calloc(1, sizeof(*kq));
    if (kq == NULL)
        return (-1);

    if (kqops.kqueue_init(kq) < 0) {
        free(kq);
        return (-1);
    }

    dbg_printf("created kqueue, fd=%d", kq->kq_id);

    tmp = map_delete(kqmap, kq->kq_id);
    if (tmp != NULL) {
        dbg_puts("FIXME -- memory leak here");
        // TODO: kqops.kqueue_free(tmp), or (better yet) decrease it's refcount
    }
    if (map_insert(kqmap, kq->kq_id, kq) < 0) {
        dbg_puts("map insertion failed");
        kqops.kqueue_free(kq);
        return (-1);
    }

    return (kq->kq_id);
}
