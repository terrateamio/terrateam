libkqueue
=========

[![CI Linux](https://github.com/mheily/libkqueue/actions/workflows/ci-linux.yml/badge.svg)](https://github.com/mheily/libkqueue/actions/workflows/ci-linux.yml)
[![CI Windows](https://github.com/mheily/libkqueue/actions/workflows/ci-windows.yml/badge.svg)](https://github.com/mheily/libkqueue/actions/workflows/ci-windows.yml)
[![Test suite FreeBSD](https://github.com/mheily/libkqueue/actions/workflows/ci-freebsd.yml/badge.svg)](https://github.com/mheily/libkqueue/actions/workflows/ci-freebsd.yml)
[![Test suite macOS](https://github.com/mheily/libkqueue/actions/workflows/ci-macos.yml/badge.svg)](https://github.com/mheily/libkqueue/actions/workflows/ci-macos.yml)
[![Coverity](https://scan.coverity.com/projects/24822/badge.svg)](https://scan.coverity.com/projects/mheily-libkqueue)

A user space implementation of the kqueue(2) kernel event notification mechanism
libkqueue acts as a translator between the kevent structure and the native
kernel facilities on Linux, Android, Solaris, and Windows.

libkqueue is not perfect, and you may need to change the behaviour of your application
to work around limitations on a given platform. Please see [BUGS](BUGS.md) for known
behavioural differences between libkqueue and BSD kqueues.

Supported Event Types
---------------------

* vnode
* socket
* proc
* user
* timer

Installation - Linux, Solaris
-----------------------------

    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib <path to source>
    make
    make install

Installation - Red Hat
----------------------

    cmake3 -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib <path to source>
    make
    cpack3 -G RPM

Installation - Debian
---------------------

    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib <path to source>
    make
    cpack -G DEB

Installation - Android
----------------------

    cmake -G "Unix Makefiles" -DCMAKE_C_COMPILER=<path to NDK compiler> -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib <path to source>
    make

Windows (Visual Studio Project)
-------------------------------

    cmake -G "Visual Studio 14 2015" <path to source>
    cmake --build .

Windows (clang/C2) (Visual Studio Project)
------------------------------------------

    cmake -G "Visual Studio 14 2015" -T "LLVM-vs2014" <path to source>
    cmake --build .

Windows (cross-compiling on Ubuntu using MinGW)
-----------------------------------------------

    sudo apt-get install mingw-w64
    rm -rf CMakeCache.txt CMakeFiles
    mkdir build
    cd build
    cmake -DCMAKE_TOOLCHAIN_FILE=Toolchain-mingw32.cmake ..
    make

Xcode (project)
---------------

    cmake -G "Xcode" <path to source>

Source archive
--------------

    mkdir -p cmake-build-source
    cd cmake-build-source
    cmake ..
    make package_source

Running Unit Tests
------------------

    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib -DENABLE_TESTING=YES -DCMAKE_BUILD_TYPE=Debug <path to source>
    make
    make test

Build & Running only the test suite
-----------------------------------
Helpful to see the behavior of the tests on systems with native `kqueue`, e.g: macOS, FreeBSD

    cd test
    cmake .
    make
    ./libkqueue-test

To enable tests which expose bugs in native kqueue implementations pass `-DWITH_NATIVE_KQUEUE_BUGS=1` to cmake.
i.e. `cmake . test/CMakeLists.txt -DWITH_NATIVE_KQUEUE_BUGS=1`.

Debugging
---------

For best results add `-DCMAKE_BUILD_TYPE=Debug` to your cmake invocation, this will disable optimisation
and add debugging symbols to ensure your debugger produces usable output, it also enables asserts.

The environmental variable `KQUEUE_DEBUG` can then be set to enable debug output from libkqueue and the test utility.

    KQUEUE_DEBUG=1 <your application>

When building under clang and some later versions of GCC, you can add the following flags:

- `-DENABLE_ASAN=YES`, enables address sansitizer (detects use after free issues, and out of bounds accesses).
- `-DENABLE_LSAN=YES`, enables leak sanitizer (detects memory leaks).
- `-DENABLE_TSAN=YES`, enables thread sanitizer (detects races).
- `-DENABLE_UBSAN=YES`, enables undefined behaviour sanitizer (detects misaligned accesses, integer wrap, divide by zero etc...).

libkqueue filter
----------------

The libkqueue filter `EVFILT_LIBKQUEUE` exposes runtime configuration options and data.  When querying/configuring libkqueue
using `EVFILT_LIBKQUEUE` the `flags` field should be set to `EV_ADD`, and the `fflags` field should be one of the
following:

- `NOTE_VERSION` return the current version as a 32bit unsigned integer in the format `MMmmpprr` (`Major`, `minor`, `patch`, `release`) in the `data` field of an entry in the eventlist.
- `NOTE_VERSION_STR` return the current version as a string in the `udata` field of an entry in the eventlist.
- `NOTE_THREAD_SAFE` defaults to on (`1`).
   - If the `data` field is `0` the global mutex will not be locked after resolving a kqueue fd
     to a kqueue structure.  The application must guarantee any given kqueue will be created and
     destroyed by the same thread.
   - If the `data` field is `1` kqueues can be created and destroyed in different threads safely.
     This may add contention around the global mutex.
- `NOTE_FORK_CLEANUP` defaults to on (`1`).
   - If the `data` field is `0` no resources will be cleaned up on fork.
   - if the `data` field is `1` all kqueues will be closed/freed on fork.

   The default behaviour matches native kqueue but may be expensive if many kqueues are active.
   If `EV_RECEIPT` is set, the previous value of cleanup flag will be provided in a receipt event.

Example - retrieving version string:

    struct kevent kev, receipt;

    EV_SET(&kev, 0, EVFILT_LIBKQUEUE, EV_ADD, NOTE_VERSION_STR, 0, NULL);
    if (kevent(kqfd, &kev, 1, &receipt, 1, &(struct timespec){}) != 1) {
        //error
    }
    printf("libkqueue version - %s", (char *)receipt.udata);

The following are only available in debugging builds of libkqueue:
- `NOTE_DEBUG` defaults to off `0`, but may be overridden by the environmental variable
  `KQUEUE_DEBUG`.
  - If the `data` field is `0` no debug messages will be produced.
  - If the `data` field is `1` debug messages will be produced.

  If `EV_RECEIPT` is set the previous value of debug flag will be provided in a receipt event.
- `NOTE_DEBUG_PREFIX` defaults to `KQ`.
  Logging prefix will be set to the value of a string pointed to by the `data` field.
  Logging prefix strings will be memdup'd.
- `NOTE_DEBUG_FUNC` defaults to a function which writes debug information to stderr.
  The `data` field should contain a pointer to a function with the signature
  `void (*debug_func)(char const *fmt, ...)`, or `NULL` to restore to original logging function.


Building Applications
---------------------

    CFLAGS += -I/usr/include/kqueue
    LDFLAGS += -lkqueue

Tutorials & Examples
--------------------

[Kqueues for Fun and Profit](http://doc.geoffgarside.co.uk/kqueue)

[Handling TCP Connections with Kqueue Event Notification](http://eradman.com/posts//kqueue-tcp.html)

Releases History
----------------

See the [ChangeLog](https://github.com/mheily/libkqueue/blob/master/ChangeLog).
