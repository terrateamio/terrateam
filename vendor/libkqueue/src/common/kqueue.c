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

/** Global control for whether we lock the kq_mtx when looking up kqueues
 */
bool libkqueue_thread_safe = true;

/** Global control for whether we perform cleanups on fork
 */
bool libkqueue_fork_cleanup = true;

/** Value is updated on fork to ensure all fork handlers are synchronised
 */
bool libkqueue_fork_cleanup_active;

/** Whether this is a child of the original process
 */
static bool libkqueue_in_child = false;

#ifdef _WIN32
tracing_mutex_t kq_mtx;
static LONG kq_init_begin = 0;
static int kq_init_complete = 0;
#else
tracing_mutex_t kq_mtx = TRACING_MUTEX_INITIALIZER;
pthread_once_t kq_is_initialized = PTHREAD_ONCE_INIT;
#endif

/** List of all active kqueues
 *
 * This is used to iterate over all active kqueues.
 *
 * kq_mtx should be held whilst accessing or modifying.
 */
struct kqueue_head kq_list;

/** Count of the active kqueues
 *
 */
unsigned int kq_cnt = 0;

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
    /*
     * The issue here is that we're not sure
     */
    if (libkqueue_in_child) {
        dbg_puts("not releasing library resources as we are a child");
        return;
    }

    dbg_puts("releasing library resources");

    filter_free_all();

    if (kqops.libkqueue_free)
        kqops.libkqueue_free();
}

#ifndef _WIN32
/** TSAN incorrectly detects data races in this function
 *
 * It's not clear why it's not recording the fact that the appropriate
 * mutexes are in fact locked... but it is:
 *
 * Write of size 4 at 0x7f2ca355e34c by thread T1 (mutexes: write M4):
 *   #0 monitoring_thread_loop /home/arr2036/Documents/Repositories/dependencies/libkqueue/src/linux/platform.c:298 (libkqueue.so.0+0xf521)
 *
 * Previous write of size 4 at 0x7f2ca355e34c by main thread:
 *   #0 libkqueue_pre_fork /home/arr2036/Documents/Repositories/dependencies/libkqueue/src/common/kqueue.c:116 (libkqueue.so.0+0xbb8c)
 *   #1 <null> <null> (libc.so.6+0x94aff)
 *   #2 test_fork /home/arr2036/Documents/Repositories/dependencies/libkqueue/test/kqueue.c:168 (libkqueue-test+0x63cf)
 *   #3 run_iteration /home/arr2036/Documents/Repositories/dependencies/libkqueue/test/main.c:82 (libkqueue-test+0x7ca3)
 *   #4 test_harness /home/arr2036/Documents/Repositories/dependencies/libkqueue/test/main.c:109 (libkqueue-test+0x7e40)
 *   #5 main /home/arr2036/Documents/Repositories/dependencies/libkqueue/test/main.c:286 (libkqueue-test+0x8889)
 */
TSAN_IGNORE
void
libkqueue_pre_fork(void)
{
    struct kqueue *kq, *kq_tmp;

    /*
     * Ensure that all global structures are in a
     * consistent state before attempting the
     * fork.
     *
     * If we don't do this then kq_mtx state will
     * be undefined when the child starts cleaning
     * up resources, and we could get deadlocks, nasty
     * memory corruption and or crashes in the child.
     */
    tracing_mutex_lock(&kq_mtx);

    /*
     * Unfortunately there's no way to remove the atfork
     * handlers, so all we can do if cleanup is
     * deactivated is bail as quickly as possible.
     *
     * We copy the value of libkqueue_fork_cleanup so
     * that it's consistent during the fork.
     */
    libkqueue_fork_cleanup_active = libkqueue_fork_cleanup;
    if (!libkqueue_fork_cleanup_active)
        return;

    /*
     * Acquire locks for all the active kqueues,
     * this ensures in the child all kqueues are in
     * a consistent state, ready to be freed.
     *
     * This has the potential to stall out the process
     * whilst we attempt to acquire all the locks,
     * so it might be a good idea to make this
     * configurable in future.
     */
    dbg_puts("gathering kqueue locks on fork");
    LIST_FOREACH_SAFE(kq, &kq_list, kq_entry, kq_tmp) {
        kqueue_lock(kq);
    }
}

void
libkqueue_parent_fork(void)
{
    struct kqueue *kq, *kq_tmp;

    if (!libkqueue_fork_cleanup_active) {
        tracing_mutex_unlock(&kq_mtx);
        return;
    }

    dbg_puts("releasing kqueue locks in parent");
    LIST_FOREACH_SAFE(kq, &kq_list, kq_entry, kq_tmp) {
        kqueue_unlock(kq);
    }
    tracing_mutex_unlock(&kq_mtx);
}

void
libkqueue_child_fork(void)
{
    struct kqueue *kq, *kq_tmp;

    libkqueue_in_child = true;

    if (!libkqueue_fork_cleanup_active) {
        tracing_mutex_unlock(&kq_mtx);
        return;
    }

    dbg_puts("releasing kqueue locks in child");
    LIST_FOREACH_SAFE(kq, &kq_list, kq_entry, kq_tmp) {
        kqueue_unlock(kq);
    }

    dbg_puts("cleaning up forked resources");
    filter_fork_all();

    if (kqops.libkqueue_fork)
        kqops.libkqueue_fork();

    tracing_mutex_unlock(&kq_mtx);
}
#endif

void
libkqueue_init(void)
{
#ifndef NDEBUG
    char *s = getenv("KQUEUE_DEBUG");
    if ((s != NULL) && (strlen(s) > 0) && (*s != '0')) {
        libkqueue_debug = 1;

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

#ifdef _WIN32
   kq_init_complete = 1;
#endif

   if (kqops.libkqueue_init)
       kqops.libkqueue_init();

   filter_init_all();

   dbg_puts("library initialization complete");

#ifndef _WIN32
   pthread_atfork(libkqueue_pre_fork, libkqueue_parent_fork, libkqueue_child_fork);
#endif

#ifndef NDEBUG
   atexit(libkqueue_debug_ident_clear);
#endif
   atexit(libkqueue_free);
}

void
kqueue_knote_mark_disabled_all(struct kqueue *kq)
{
    unsigned int i;

    for (i = 0; i < EVFILT_SYSCOUNT; i++) {
        struct filter *kf = &kq->kq_filt[i];
        knote_mark_disabled_all(kf);
    }
}

/** Free a kqueue, must be called with the kq_mtx held
 *
 */
void
kqueue_free(struct kqueue *kq)
{
    /*
     * Because this can be called during fork
     * processing the locker and unlocker may
     * be different.
     */
    tracing_mutex_assert_state(&kq_mtx, MTX_LOCKED);

    dbg_printf("kq=%p - freeing", kq);

    kq_cnt--;
    LIST_REMOVE(kq, kq_entry);

    /*
     * map_remove ensures the current map entry
     * points to this kqueue.
     *
     * If it doesn't we leave it alone and just
     * free the kq.
     */
    map_remove(kqmap, kq->kq_id, kq);

    /*
     * Ensure no other thread has any ongoing
     * operations on this kqueue.  Unlikely but
     * keeps TSAN Happy.
     */
    kqueue_lock(kq);
    filter_unregister_all(kq);
    kqops.kqueue_free(kq);
    kqueue_unlock(kq);

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
    int prev_cancel_state;
    tracing_mutex_lock(&kq_mtx);
    (void) pthread_once(&kq_is_initialized, libkqueue_init);
    tracing_mutex_unlock(&kq_mtx);
#endif

#ifndef _WIN32
    prev_cancel_state = pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, NULL);
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
        tracing_mutex_unlock(&kq_mtx);
    error:
        dbg_printf("kq=%p - init failed", kq);
        tracing_mutex_destroy(&kq->kq_mtx);
        free(kq);
#ifndef _WIN32
        pthread_setcancelstate(prev_cancel_state, NULL);
#endif
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
    LIST_INSERT_HEAD(&kq_list, kq, kq_entry);
    kq_cnt++;
    tracing_mutex_unlock(&kq_mtx);
#ifndef _WIN32
    pthread_setcancelstate(prev_cancel_state, NULL);
    if (prev_cancel_state == PTHREAD_CANCEL_ENABLE)
        pthread_testcancel();
#endif

    return (kq->kq_id);
}
