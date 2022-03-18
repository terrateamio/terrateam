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
#include <signal.h>

#include "private.h"

int DEBUG_KQUEUE = 0;
char *KQUEUE_DEBUG_IDENT = "KQ";

#ifdef _WIN32
tracing_mutex_t kq_mtx;
static LONG kq_init_begin = 0;
static int kq_init_complete = 0;
#else
tracing_mutex_t kq_mtx = TRACING_MUTEX_INITIALIZER;
pthread_once_t kq_is_initialized = PTHREAD_ONCE_INIT;
#endif

unsigned int
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

unsigned int
get_fd_used(void)
{
    unsigned int fd_max = get_fd_limit();
    unsigned int i;
    unsigned int used = 0;
    int our_errno = errno; /* Preserve errno */

#ifdef __linux__
    for (i = 0; i < fd_max; i++) {
        if (fcntl(i, F_GETFD) == 0)
            used++;
    }
#endif

    errno = our_errno;

    return used;
}

static struct map *kqmap;

void
libkqueue_free(void)
{
    dbg_puts("Releasing library resources");

    if (kqops.libkqueue_free)
        kqops.libkqueue_free();
}

void
libkqueue_init(void)
{
#ifdef NDEBUG
    DEBUG_KQUEUE = 0;
#else
    char *s = getenv("KQUEUE_DEBUG");
    if ((s != NULL) && (strlen(s) > 0) && (*s != '0')) {
        DEBUG_KQUEUE = 1;

#ifdef _WIN32
    tracing_mutex_init(&kq_mtx, NULL);
    /* Initialize the Winsock library */
    WSADATA wsaData;
    if (WSAStartup(MAKEWORD(2,2), &wsaData) != 0)
        abort();
#endif

# if defined(_WIN32) && !defined(__GNUC__)
    /* Enable heap surveillance */
    {
        int tmpFlag = _CrtSetDbgFlag( _CRTDBG_REPORT_FLAG );
        tmpFlag |= _CRTDBG_CHECK_ALWAYS_DF;
        _CrtSetDbgFlag(tmpFlag);
    }
# endif /* _WIN32 */
    }
#endif

   kqmap = map_new(get_fd_limit()); // INT_MAX
   if (kqmap == NULL)
       abort();
   if (knote_init() < 0)
       abort();

#ifdef _WIN32
   kq_init_complete = 1;
#endif

   if (kqops.libkqueue_init)
       kqops.libkqueue_init();

   dbg_puts("library initialization complete");

   atexit(libkqueue_free);
}

void
kqueue_free(struct kqueue *kq)
{
    dbg_printf("kq=%p - freeing", kq);

    /*
     * map_remove ensures the current map entry
     * points to this kqueue.
     *
     * If it doesn't we leave it alone and just
     * free the kq.
     */
    map_remove(kqmap, kq->kq_id, kq);

    filter_unregister_all(kq);
    kqops.kqueue_free(kq);
    tracing_mutex_destroy(&kq->kq_mtx);

#ifndef NDEBUG
    memset(kq, 0x42, sizeof(*kq));
#endif
    free(kq);
}

void
kqueue_free_by_id(int id)
{
    struct kqueue *kq;

    kq = map_delete(kqmap, id);
    if (!kq) return;

    kqueue_free(kq);
}

struct kqueue *
kqueue_lookup(int kq)
{
    return ((struct kqueue *) map_lookup(kqmap, kq));
}

int VISIBLE
kqueue(void)
{
    struct kqueue *kq;

#ifdef _WIN32
    if (InterlockedCompareExchange(&kq_init_begin, 0, 1) == 0) {
        libkqueue_init();
    } else {
        while (kq_init_complete == 0) {
            sleep(1);
        }
    }

    tracing_mutex_init(&kq_mtx, NULL);
#else
    tracing_mutex_lock(&kq_mtx);
    (void) pthread_once(&kq_is_initialized, libkqueue_init);
    tracing_mutex_unlock(&kq_mtx);
#endif

    kq = calloc(1, sizeof(*kq));
    if (kq == NULL)
        return (-1);

    tracing_mutex_init(&kq->kq_mtx, NULL);

    /*
     * Init, delete and insert should be atomic
     * this is mainly for the monitoring thread
     * on Linux, to ensure if an FD gets reused
     * for a new KQ, the signal handler doesn't
     * accidentally free up memory allocated to
     * the new KQ.
     */
    tracing_mutex_lock(&kq_mtx);
    if (kqops.kqueue_init(kq) < 0) {
    error:
        dbg_printf("kq=%p - init failed", kq);
        tracing_mutex_destroy(&kq->kq_mtx);
        free(kq);
        return (-1);
    }

    dbg_printf("kq=%p - alloced with fd=%d", kq, kq->kq_id);

    kqueue_free_by_id(kq->kq_id);   /* Free any old map entries */

    if (map_insert(kqmap, kq->kq_id, kq) < 0) {
        dbg_printf("kq=%p - map insertion failed, freeing", kq);
        filter_unregister_all(kq);
        tracing_mutex_unlock(&kq_mtx);
        goto error;
    }
    tracing_mutex_unlock(&kq_mtx);

    return (kq->kq_id);
}
