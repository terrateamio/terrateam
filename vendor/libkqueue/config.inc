program="libkqueue"
version="0.2"
cflags="-fPIC -I./include -I./src/common -Wall -Werror"
sources="src/common/*.c"
mans="kqueue.2"
headers="private.h"
extra_dist="*.in README"
subdirs="src include test"

pre_configure_hook() {
  if [ "$debug" = "yes" ] ; then
      cflags="$cflags -DKQUEUE_DEBUG"
  fi

  if [ $target = "linux" ] ; then
      required_headers="sys/epoll.h sys/inotify.h"
      optional_headers="sys/signalfd.h sys/timerfd.h"
  fi
}

post_configure_hook() {
    if [ $target = "linux" ] ; then
       if [ "$have_sys_signalfd_h" = "no" -o "$have_sys_timerfd_h" = "no" ]
       then
         echo "** ERROR: Your kernel and/or C library are too old."
         echo "**        At least kernel 2.6.22 and glibc 2.8 are required."
         exit 1
       fi
    fi

    finalize target "$target"
    sources="$sources src/$target/*.c"
}
