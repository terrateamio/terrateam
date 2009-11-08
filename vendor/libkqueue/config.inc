program="libkqueue"
version="0.2"
cflags="-fPIC -I./include -Wall -Werror"
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
         echo "** NOTE: The Linux backend requires at least kernel 2.6.22 "
         echo "**       and glibc 2.8. Switching to the POSIX backend."
         target=posix
       fi
    fi
    finalize target "$target"
}
