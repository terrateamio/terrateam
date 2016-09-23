
# FIXME - Only supports Linux for now

kqincludedir = $(includedir)/kqueue/sys

if INSTALL
    lib_LTLIBRARIES = libkqueue.la
    kqinclude_HEADERS = include/sys/event.h
    dist_man_MANS = kqueue.2
else
    noinst_LTLIBRARIES = libkqueue.la
endif

libkqueue_la_CFLAGS = -I$(top_srcdir)/src/common -I$(top_srcdir)/include -Wall -Wextra -Wno-missing-field-initializers -Werror -g -O2 -std=c99 -D_XOPEN_SOURCE=600 -fvisibility=hidden

libkqueue_la_SOURCES = \
       src/common/filter.c \
       src/common/knote.c \
       src/common/map.c \
       src/common/kevent.c \
       src/common/kqueue.c \
       src/posix/platform.c \
       src/posix/platform.h \
       src/linux/platform.c \
       src/linux/read.c \
       src/linux/write.c \
       src/linux/user.c \
       src/linux/vnode.c \
       src/linux/signal.c \
       src/linux/timer.c \
       src/common/alloc.h \
       src/common/debug.h \
       src/common/private.h \
       src/common/queue.h \
       src/common/tree.h \
       src/linux/platform.h

if !BIONIC_LIBC
libkqueue_la_LIBADD = -lpthread -lrt
endif

pkgconfigdir=$(libdir)/pkgconfig
pkgconfig_DATA=libkqueue.pc

check_PROGRAMS = kqtest

TESTS = kqtest

kqtest_SOURCES = \
       test/main.c \
       test/kevent.c \
       test/test.c \
       test/proc.c \
       test/read.c \
       test/signal.c \
       test/timer.c \
       test/vnode.c \
       test/user.c \
       test/common.h

kqtest_CFLAGS = -g -O0 -Wall -Werror -I$(top_srcdir)/include -I$(top_srcdir)/test -I$(builddir)

if BIONIC_LIBC
kqtest_LDADD = libkqueue.la
else
kqtest_LDADD = -lpthread -lrt libkqueue.la
endif


