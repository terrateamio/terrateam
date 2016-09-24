#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_INIT([libkqueue], [2.1.0])
LT_INIT
AM_INIT_AUTOMAKE([foreign subdir-objects])
AC_CONFIG_SRCDIR([configure.ac])
AC_CONFIG_HEADERS([config.h])
AC_PROG_CC

# When building as submodule allow selection of noinst targets
AC_ARG_ENABLE([libkqueue-install],
  [AS_HELP_STRING([--disable-libkqueue-install],
    [Disable install rules and build noinst libtool library])],,
  [enable_libkqueue_install=yes]
)
AM_CONDITIONAL([INSTALL],[test "x$enable_libkqueue_install" != "xno"])

# Add option to provide Bionic Libc (Android) support
AC_ARG_ENABLE([bionic-libc],
  [AS_HELP_STRING([--enable-bionic-libc],
    [Build for Bionic Libc (Android)])],,
  [enable_bionic_libc=no]
)
AM_CONDITIONAL(BIONIC_LIBC, [test "x$enable_bionic_libc" == "xyes"])

AC_CHECK_HEADER([sys/event.h])
AC_CHECK_DECL([EPOLLRDHUP], [], [], [[#include <sys/epoll.h>]])
AC_CHECK_DECL([ppoll], [], [], [[
#define _GNU_SOURCE
#include <poll.h>
]])
AC_CHECK_HEADERS([sys/epoll.h sys/inotify.h sys/signalfd.h sys/timerfd.h sys/eventfd.h])


AC_CONFIG_FILES([Makefile libkqueue.pc])
AC_OUTPUT
