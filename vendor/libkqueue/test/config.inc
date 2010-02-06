#!/bin/sh

program=libkqueue-test
version=0.1
cflags="-g -O0 -rdynamic -Wall -Werror"
sources="main.c kevent.c test.c proc.c read.c signal.c timer.c vnode.c"

pre_configure_hook() {
 
  check_header "err.h"
  check_header "sys/event.h" \
      && sys_event_h="sys/event.h" \
      || {
            sys_event_h="../include/sys/event.h"
            cflags="$cflags -I../include"
            ldadd="$ldadd ../libkqueue.a -lpthread -lrt"
         }

  test "$target" = "solaris" && ldadd="$ldadd -lsocket"

  check_symbol $sys_event_h EV_DISPATCH
  check_symbol $sys_event_h EV_RECEIPT
  check_symbol $sys_event_h NOTE_TRUNCATE 
  check_symbol $sys_event_h EVFILT_TIMER
  check_symbol $sys_event_h EVFILT_USER && \
     sources="$sources user.c"
}
