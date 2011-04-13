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

#ifndef  _DEBUG_H
#define  _DEBUG_H

#include <assert.h>

extern int DEBUG_ACTIVE;
extern char *DEBUG_IDENT;

#if defined(__linux__)
# define THREAD_ID ((pid_t)  syscall(__NR_gettid))
#elif defined(__sun)
# define THREAD_ID (pthread_self())
#elif defined(_WIN32)
# define THREAD_ID (int)(GetCurrentThreadId())
#else 
# error Unsupported platform
#endif


#ifndef NDEBUG
#define dbg_puts(str)           do {                                \
    if (DEBUG_ACTIVE)                                                      \
      fprintf(stderr, "%s [%d]: %s(): %s\n",                        \
              DEBUG_IDENT, THREAD_ID, __func__, str);               \
} while (0)

#define dbg_printf(fmt,...)     do {                                \
    if (DEBUG_ACTIVE)                                                      \
      fprintf(stderr, "%s [%d]: %s(): "fmt"\n",                     \
              DEBUG_IDENT, THREAD_ID, __func__, __VA_ARGS__);       \
} while (0)

#define dbg_perror(str)         do {                                \
    if (DEBUG_ACTIVE)                                                      \
      fprintf(stderr, "%s [%d]: %s(): %s: %s (errno=%d)\n",         \
              DEBUG_IDENT, THREAD_ID, __func__, str,                \
              strerror(errno), errno);                              \
} while (0)

# define reset_errno()          do { errno = 0; } while (0)

# if defined(_WIN32)
#  define dbg_lasterror(str)     do {                                \
    if (DEBUG_ACTIVE)                                                      \
      fprintf(stderr, "%s: [%d] %s(): %s: (LastError=%d)\n",        \
              DEBUG_IDENT, THREAD_ID, __func__, str, (int)GetLastError());            \
} while (0)
# else
#  define dbg_lasterror(str)     ;
# endif

#else /* NDEBUG */
# define dbg_puts(str)           ;
# define dbg_printf(fmt,...)     ;
# define dbg_perror(str)         ;
# define dbg_lasterror(str)      ;
# define reset_errno()           ;
#endif 

#endif  /* ! _DEBUG_H */
