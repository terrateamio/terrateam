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

#include <sys/types.h>
#include <limits.h>
#include <pthread.h>

#include "common.h"

static int __thread testnum = 1;
static int __thread error_flag = 1;
static char __thread * cur_test_id = NULL;

static void
testing_atexit(void)
{
    if (error_flag) {
        printf(" *** TEST FAILED: %s\n", cur_test_id);
        //TODO: print detailed log
    } else {
        printf("\n---\n"
                "+OK All %d tests completed.\n", testnum - 1);
    }
}

void
test_begin(const char *func)
{
    if (cur_test_id)
        free(cur_test_id);
    cur_test_id = strdup(func);

    printf("%d: %s\n", testnum++, cur_test_id);
    //TODO: redirect stdout/err to logfile
}

void
test_end(void)
{
    free(cur_test_id);
    cur_test_id = NULL;
}

void
testing_begin(void)
{
    atexit(testing_atexit);
}

void
testing_end(void)
{
    error_flag = 0;
}

/* Generate a unique ID */
int
testing_make_uid(void)
{
    static pthread_mutex_t mtx = PTHREAD_MUTEX_INITIALIZER;
    static int id = 0;

    pthread_mutex_lock(&mtx);
    if (id == INT_MAX)
        abort();
    id++;
    pthread_mutex_unlock(&mtx);

    return (id);
}
