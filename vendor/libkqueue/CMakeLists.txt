#
# Copyright (c) 2011 Marius Zwicker <marius@mlba-team.de>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

cmake_minimum_required(VERSION 2.8.4)
cmake_policy(SET CMP0063 OLD)

project(kqueue C)

set(CMAKE_C_VISIBILITY_PRESET hidden)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 99)

option(STATIC_KQUEUE "build libkqueue as static library" OFF)
option(ENABLE_TESTS "build tests for libkqueue" OFF)

set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
set(THREADS_PREFER_PTHREADS_FLAG TRUE)
find_package(Threads REQUIRED)

include(CheckIncludeFiles)
include(CheckSymbolExists)

check_include_files(sys/signalfd.h HAVE_SYS_SIGNALFD_H)
check_include_files(sys/timerfd.h HAVE_SYS_TIMERFD_H)
check_include_files(sys/eventfd.h HAVE_SYS_EVENTFD_H)
if(ENABLE_TESTS)
  check_include_files(err.h HAVE_ERR_H)
endif()

check_symbol_exists(EPOLLRDHUP sys/epoll.h HAVE_EPOLLRDHUP)
check_symbol_exists(NOTE_TRUNCATE sys/event.h HAVE_NOTE_TRUNCATE)
if(ENABLE_TESTS)
  check_symbol_exists(NOTE_REVOKE sys/event.h HAVE_NOTE_REVOKE)
endif()

set(CMAKE_REQUIRED_DEFINITIONS -D_GNU_SOURCE)
check_symbol_exists(ppoll poll.h HAVE_DECL_PPOLL)

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/config.h.in
               ${CMAKE_CURRENT_BINARY_DIR}/config.h)
include_directories(${CMAKE_CURRENT_BINARY_DIR})

set(LIBKQUEUE_HEADERS
    include/sys/event.h)

set(LIBKQUEUE_SOURCES
    src/common/alloc.h
    src/common/debug.h
    src/common/filter.c
    src/common/kevent.c
    src/common/knote.c
    src/common/kqueue.c
    src/common/map.c
    src/common/private.h
    src/common/queue.h
    src/common/tree.h)

if(CMAKE_SYSTEM_NAME MATCHES Windows)
  list(APPEND LIBKQUEUE_SOURCES
       src/windows/platform.c
       src/windows/platform.h
       src/windows/read.c
       src/windows/stdint.h
       src/windows/timer.c
       src/windows/user.c)
elseif(CMAKE_SYSTEM_NAME MATCHES "(Solaris|SunOS)")
  list(APPEND LIBKQUEUE_SOURCES
       src/posix/platform.c
       src/posix/platform.h
       src/solaris/platform.c
       src/solaris/platform.h
       src/solaris/signal.c
       src/solaris/socket.c
       src/solaris/timer.c
       src/solaris/user.c)
elseif(CMAKE_SYSTEM_NAME STREQUAL Linux)
  list(APPEND LIBKQUEUE_SOURCES
       src/posix/platform.c
       src/posix/platform.h
       src/linux/platform.c
       src/linux/platform.h
       src/linux/read.c
       src/linux/signal.c
       src/linux/timer.c
       src/linux/user.c
       src/linux/vnode.c
       src/linux/write.c)
else()
  message(FATAL_ERROR "unsupported host os")
endif()

source_group(includes
             FILES
               ${LIBKQUEUE_HEADERS})
source_group(src
             FILES
               ${LIBKQUEUE_SOURCES})

if(STATIC_KQUEUE)
  set(LIBRARY_TYPE STATIC)
else()
  set(LIBRARY_TYPE SHARED)
endif()

add_library(kqueue ${LIBRARY_TYPE} ${LIBKQUEUE_SOURCES} ${LIBKQUEUE_HEADERS})
set_target_properties(kqueue PROPERTIES DEBUG_POSTFIX "D")

if(WIN32)
  target_compile_definitions(kqueue PRIVATE _USRDLL;_WINDLL)
  target_compile_definitions(kqueue PRIVATE _CRT_SECURE_NO_WARNINGS)
else()
  target_compile_definitions(kqueue PRIVATE _XOPEN_SOURCE=600)
endif()

target_include_directories(kqueue PRIVATE include)
if(NOT WIN32)
  target_include_directories(kqueue PRIVATE src/common)
endif()

if(CMAKE_C_COMPILER_ID MATCHES GNU)
  target_compile_options(kqueue PRIVATE -Wall -Werror)
endif()
if(MINGW AND CMAKE_C_COMPILER_ID MATCHES GNU)
  target_compile_options(kqueue PRIVATE -march=i486)
endif()

if(WIN32)
  target_link_libraries(kqueue PRIVATE Ws2_32)
endif()
target_link_libraries(kqueue PRIVATE ${CMAKE_THREAD_LIBS_INIT})

if(ENABLE_TESTS)
  add_subdirectory(test)
endif()

