#!/bin/sh

program=libkqueue-test
version=0.1
cflags="-g -O0 -Wall -Werror"
sources="main.c read.c signal.c timer.c vnode.c"

pre_configure_hook() {
  check_header sys/event.h && {
      check_symbol sys/event.h EV_DISPATCH
      check_symbol sys/event.h EV_RECEIPT
      check_symbol sys/event.h EVFILT_USER && \
          sources="$sources user.c"
      check_symbol sys/event.h EVFILT_TIMER
  }

  if [ "`uname -s`" = "Linux" ] ; then
     cflags="$cflags -I../include"
     ldadd="$ldadd ../libkqueue.a"
  fi
}
