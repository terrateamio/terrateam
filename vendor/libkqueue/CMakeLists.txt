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

if(EXISTS "/etc/debian_version")
  cmake_minimum_required(VERSION 3.7.2)
else()
  # KLUDGE: assumes RPM here
  # For RPM packaging to work correctly version >= 3.8 is required
  cmake_minimum_required(VERSION 3.8.0)
endif()
cmake_policy(SET CMP0063 OLD)

project(libkqueue VERSION 2.4.0 LANGUAGES C)
enable_testing()

set(CMAKE_C_VISIBILITY_PRESET hidden)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 99)
set(CMAKE_BUILD_TYPE RelWithDebInfo)

option(STATIC_KQUEUE "build libkqueue as static library" OFF)

set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
set(THREADS_PREFER_PTHREAD_FLAG TRUE)
find_package(Threads REQUIRED)

include(CheckIncludeFiles)
include(CheckSymbolExists)
include(GNUInstallDirs)

check_include_files(sys/signalfd.h HAVE_SYS_SIGNALFD_H)
check_include_files(sys/timerfd.h HAVE_SYS_TIMERFD_H)
check_include_files(sys/eventfd.h HAVE_SYS_EVENTFD_H)
if(ENABLE_TESTING)
  check_include_files(err.h HAVE_ERR_H)
endif()

check_symbol_exists(EPOLLRDHUP sys/epoll.h HAVE_EPOLLRDHUP)
check_symbol_exists(NOTE_TRUNCATE sys/event.h HAVE_NOTE_TRUNCATE)
if(ENABLE_TESTING)
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
  #
  #  Set the default prefix to something sane
  #
  if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set (CMAKE_INSTALL_PREFIX "/usr" CACHE PATH "default install path" FORCE )
  endif()

  #
  #  Set library directory correctly if we're building 64bit libraries
  #
  get_property(LIB64 GLOBAL PROPERTY FIND_LIBRARY_USE_LIB64_PATHS)
  if ("${LIB64}" STREQUAL "TRUE")
    set(LIB_SUFFIX 64)
  else()
    set(LIB_SUFFIX "")
  endif()
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
set_target_properties(kqueue PROPERTIES DEBUG_POSTFIX "d")
set_target_properties(kqueue PROPERTIES SOVERSION 1)

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
target_link_libraries(kqueue PRIVATE Threads::Threads)

if(ENABLE_TESTING)
  add_subdirectory(test)
endif()

configure_file("${CMAKE_SOURCE_DIR}/libkqueue.pc.in"
               "${CMAKE_BINARY_DIR}/libkqueue.pc"
               @ONLY)

#
#  Avoid conflicts by not trying to create existing directories
#
set(CPACK_RPM_EXCLUDE_FROM_AUTO_FILELIST_ADDITION ${CMAKE_INSTALL_FULL_MANDIR}
                                                  ${CMAKE_INSTALL_FULL_MANDIR}/man2
                                                  ${CMAKE_INSTALL_FULL_INCLUDEDIR}/sys
                                                  ${CMAKE_INSTALL_FULL_LIBDIR}${LIB_SUFFIX}/pkgconfig)

install(FILES
          "include/sys/event.h"
        DESTINATION
          "${CMAKE_INSTALL_FULL_INCLUDEDIR}/kqueue/sys"
        COMPONENT headers)
install(TARGETS
          kqueue
        DESTINATION
          "${CMAKE_INSTALL_FULL_LIBDIR}${LIB_SUFFIX}"
        COMPONENT libraries)
install(FILES
          kqueue.2
        DESTINATION
          "${CMAKE_INSTALL_FULL_MANDIR}/man2"
        COMPONENT man)
install(FILES
          "${CMAKE_BINARY_DIR}/libkqueue.pc"
        DESTINATION
          "${CMAKE_INSTALL_FULL_LIBDIR}${LIB_SUFFIX}/pkgconfig"
        COMPONENT pkgconfig)

set(CPACK_PACKAGE_NAME ${PROJECT_NAME})
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Mark Heily <mark@heily.com>")

# Specify the location of source files to be installed by the debuginfo package
set(CPACK_BUILD_SOURCE_DIRS ${CMAKE_SOURCE_DIR}/src)

# Group the components into packages
# - devel contains header files and man pages and becomes libkqueue-devel
# - main contains everything else and becomes libkqueue
set(CPACK_COMPONENT_HEADERS_GROUP "devel")
set(CPACK_COMPONENT_LIBRARIES_GROUP "main")
set(CPACK_COMPONENT_MAN_GROUP "devel")
set(CPACK_COMPONENT_PKGCONFIG_GROUP "main")
set(CPACK_COMPONENT_HEADERS_DEPENDS "libraries")

#
#  Metadata common to all packaging systems
#
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Userspace implementation of the kqueue event notification mechanism")

set(CPACK_COMPONENT_MAIN_DESCRIPTION "A user space implementation of the kqueue(2) kernel event notification mechanism. libkqueue acts as a translator between the kevent structure and the native kernel facilities.")
set(CPACK_COMPONENT_DEVEL_DESCRIPTION "Development files for ${PROJECT_NAME}-${PROJECT_VERSION}")

#
#  RPM Specific configuration
#
set(CPACK_RPM_PACKAGE_LICENSE "MIT and BSD")
set(CPACK_RPM_PACKAGE_URL "http://sourceforge.net/p/libkqueue/wiki/Home/")

set(CPACK_RPM_MAIN_PACKAGE_GROUP "System Environment/Libraries")
set(CPACK_RPM_MAIN_PACKAGE_DESCRIPTION ${CPACK_COMPONENT_MAIN_DESCRIPTION})

set(CPACK_RPM_DEVEL_PACKAGE_GROUP "Development/Libraries")
set(CPACK_RPM_DEVEL_PACKAGE_SUMMARY ${CPACK_COMPONENT_DEVEL_DESCRIPTION})
set(CPACK_RPM_DEVEL_PACKAGE_REQUIRES "${CPACK_PACKAGE_NAME} = %{version}-%{release}")

set(CPACK_RPM_MAIN_COMPONENT "main")            # Nominate the component to be packed into libkqueue
set(CPACK_RPM_COMPONENT_INSTALL ON)             # Enable component based packaging (generate multiple packages)
set(CPACK_RPM_FILE_NAME RPM-DEFAULT)            # Use rpmbuild's package naming scheme

#
#  Build a debuginfo package containing the source an debugging symbols
#
set(CPACK_RPM_MAIN_DEBUGINFO_PACKAGE ON)
set(CPACK_RPM_DEBUGINFO_SINGLE_PACKAGE ON)
set(CPACK_RPM_MAIN_BUILD_SOURCE_DIRS_PREFIX /usr/src/debug/${PROJECT_NAME}-${PROJECT_VERSION})

#
#  DEB Specific configuration
#
set(CPACK_DEBIAN_MAIN_PACKAGE_NAME "${CPACK_PACKAGE_NAME}")
set(CPACK_DEBIAN_MAIN_PACKAGE_SECTION "libs")

set(CPACK_DEBIAN_DEVEL_PACKAGE_NAME "${CPACK_PACKAGE_NAME}-dev")
set(CPACK_DEBIAN_DEVEL_PACKAGE_SECTION "libdevel")
set(CPACK_DEBIAN_DEVEL_PACKAGE_DEPENDS "${CPACK_PACKAGE_NAME} (= ${PROJECT_VERSION})")

set(CPACK_DEB_COMPONENT_INSTALL ON)             # Enable component based packaging (generate multiple packages)
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)         # Use default Debian package naming scheme
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
set(CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS ON)

include(CPack)

add_custom_target(tarball git archive -o "libkqueue-${PROJECT_VERSION}.tar.gz" --prefix "libkqueue-${PROJECT_VERSION}/" HEAD)
