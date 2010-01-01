program="libkqueue"
version="0.4"
cflags="-fPIC -fvisibility=hidden -I./include -I./src/common -Wall -Werror"
sources="src/common/filter.c src/common/knote.c 
         src/common/kevent.c src/common/kqueue.c" 
libdepends=""
deps="src/common/private.h"
mans="kqueue.2"
headers="src/common/private.h"
extra_dist="*.in"
subdirs="src include test"

# Package metadata
pkg_summary="Emulates the kqueue and kevent system calls"
pkg_description="Emulates the kqueue and kevent system calls"
license="BSD"
author="Mark Heily"

pre_configure_hook() {
  if [ "$debug" = "yes" ] ; then
      cflags="$cflags -g3 -O0 -DKQUEUE_DEBUG"
  else
      cflags="$cflags -g -O2"
  fi

  optional_headers="err.h"

  libdepends=" -L$libdir"
  if [ $target = "linux" ] ; then
      libdepends="$libdepends -lpthread -lrt"
      required_headers="sys/epoll.h sys/inotify.h 
                        sys/signalfd.h sys/timerfd.h sys/eventfd.h"
  fi
}

post_configure_hook() {
    finalize target "$target"

    evfilt_signal="src/$target/signal.c"
    evfilt_proc="src/$target/proc.c"
    evfilt_socket="src/$target/socket.c"
    evfilt_timer="src/$target/timer.c"
    evfilt_user="src/$target/user.c"
    evfilt_vnode="src/$target/vnode.c"

    if [ $target = "linux" ] ; then
      if [ "$have_sys_signalfd_h" != "yes" ] ; then
          evfilt_signal="src/posix/signal.c"
      fi
      if [ "$have_sys_timerfd_h" != "yes" ] ; then
          evfilt_timer=""      # TODO: "src/posix/timer.c"
      fi
      if [ "$have_sys_eventfd_h" != "yes" ] ; then
          evfilt_user=""      # TODO: "src/posix/user.c"
      fi
    fi      

    sources="$sources src/$target/hook.c $evfilt_signal $evfilt_proc 
             $evfilt_socket $evfilt_timer $evfilt_user $evfilt_vnode"
}
