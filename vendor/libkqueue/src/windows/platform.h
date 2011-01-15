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

#ifndef  _KQUEUE_WINDOWS_PLATFORM_H
#define  _KQUEUE_WINDOWS_PLATFORM_H

#include <winsock2.h>
#include <ws2tcpip.h>
#include <io.h>
#include <stdio.h>
#include <fcntl.h>

#pragma comment(lib, "Ws2_32.lib")

/*
 * Atomic integer operations 
 */
#define atomic_inc   InterlockedIncrement
#define atomic_dec   InterlockedDecrement

/* DllMain() is the only available constructor function */
#define CONSTRUCTOR int

/* Function visibility macros */
#define VISIBLE __declspec(dllexport)
#define HIDDEN  

#ifndef __func__
#define __func__ __FUNCDNAME__
#endif

#define snprintf _snprintf
#define ssize_t  SSIZE_T

/* For POSIX compatibility when compiling, not for actual use */
typedef int socklen_t;
typedef int nlink_t;
typedef int timer_t;
typedef int pthread_t;
typedef int sigset_t;

#define THREAD_ID   (GetCurrentThreadId())
#define __thread    __declspec(thread)

/* Emulation of pthreads mutex functionality */
typedef CRITICAL_SECTION pthread_mutex_t;
typedef CRITICAL_SECTION pthread_rwlock_t;
#define _cs_init(x)  InitializeCriticalSection((x))
#define _cs_lock(x)  EnterCriticalSection ((x))
#define _cs_unlock(x)  LeaveCriticalSection ((x))
#define pthread_mutex_lock _cs_lock
#define pthread_mutex_unlock _cs_unlock
#define pthread_mutex_init(x,y) _cs_init((x))
#define pthread_rwlock_rdlock _cs_lock
#define pthread_rwlock_wrlock _cs_lock
#define pthread_rwlock_unlock _cs_unlock
#define pthread_rwlock_init(x,y) _cs_init((x))

#define VISIBLE_DECL(t,x) __declspec(dllexport) t x

#include "../../include/sys/event.h"
/*
 * Hooks and prototypes
 */
#define kqueue_free_hook      windows_kqueue_free
void    windows_kqueue_free(struct kqueue *);

#define kqueue_init_hook      windows_kqueue_init
int     windows_kqueue_init(struct kqueue *);

#endif  /* ! _KQUEUE_WINDOWS_PLATFORM_H */
