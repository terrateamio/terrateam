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

set(PROJECT_VERSION 2.6.1)

if(EXISTS "/etc/debian_version")
  cmake_minimum_required(VERSION 3.7.2)
else()
  # KLUDGE: assumes RPM here
  # For RPM packaging to work correctly version >= 3.8 is required
  cmake_minimum_required(VERSION 3.8.0)
endif()

# Both variables used in src/version.h.in
string(TIMESTAMP PROJECT_VERSION_DATE "%b %d %Y at %H:%M:%S")

execute_process(COMMAND git rev-parse --short=8 HEAD
                OUTPUT_VARIABLE LIBKQUEUE_VERSION_COMMIT
                OUTPUT_STRIP_TRAILING_WHITESPACE
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

if(LIBKQUEUE_VERSION_COMMIT STREQUAL "")
	unset(LIBKQUEUE_VERSION_COMMIT)
endif()

# The version may be overridden when building packages by defining
# VERSION_OVERRIDE. Otherwise try to pull the number of commits
# since last tag from git to get a unique version number.
if(VERSION_OVERRIDE)
  MESSAGE("Version ${VERSION_OVERRIDE} (${LIBKQUEUE_VERSION_COMMIT}) [override]")
  set(PROJECT_VERSION "${VERSION_OVERRIDE}")
  set(CPACK_PACKAGE_VERSION "${VERSION_OVERRIDE}")
else()
  execute_process(COMMAND sh -c "git describe --tags --match 'v*' | grep '-' | cut -d- -f2"
                  OUTPUT_VARIABLE PROJECT_VERSION_RELEASE
                  OUTPUT_STRIP_TRAILING_WHITESPACE
                  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

  if(PROJECT_VERSION_RELEASE STREQUAL "")
    MESSAGE("Version ${PROJECT_VERSION} (${LIBKQUEUE_VERSION_COMMIT})")
    unset(PROJECT_VERSION_RELEASE)
  else()
    # Release 1 is the default, so we need to start at release 2
    MATH(EXPR PROJECT_VERSION_RELEASE "${PROJECT_VERSION_RELEASE}+1")
    MESSAGE("Version ${PROJECT_VERSION}-${PROJECT_VERSION_RELEASE} (${LIBKQUEUE_VERSION_COMMIT})")
    set(LIBKQUEUE_VERSION_RELEASE ${PROJECT_VERSION_RELEASE})
  endif()
endif()

project(libkqueue VERSION ${PROJECT_VERSION}
                  LANGUAGES C)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/version.h.in
               ${CMAKE_CURRENT_BINARY_DIR}/version.h @ONLY)

enable_testing()

set(CMAKE_C_VISIBILITY_PRESET hidden)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE RelWithDebInfo)
endif()

#
# Address Sanitize
#
if(ENABLE_ASAN)
  #
  # -fsanitize=address           - Build with address sanitizer support
  # -fno-omit-frame-pointer      - Always keep the frame pointer in a register
  # -fno-optimize-sibling-calls  - Don't optimize away tail recursion.
  #
  set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -fno-omit-frame-pointer -fno-optimize-sibling-calls")
  list(APPEND DEBUG_FSANITIZERFLAGS "address")
  MESSAGE("ENABLING ASAN")
endif()

#
# LeakSanitizer
#
if(ENABLE_LSAN)
  #
  # -fsanitize=leak  - Build with lsan support
  #
  list(APPEND DEBUG_FSANITIZERFLAGS "leak")
  MESSAGE("ENABLING LSAN")
endif()

#
# UndefinedBehaviour
#
if(ENABLE_UBSAN)
  #
  # -fsanitize=undefined    - Build with ubsan support
  # -fno-omit-frame-pointer - Always keep the frame pointer in a register
  #
  set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -fno-sanitize-recover=undefined -fno-omit-frame-pointer")
  set(CMAKE_LD_FLAGS_DEBUG "${CMAKE_LD_FLAGS_DEBUG} -fno-sanitize-recover=undefined")
  list(APPEND DEBUG_FSANITIZERFLAGS "undefined")
  MESSAGE("ENABLING UBSAN")
endif()

#
# ThreadSanitizer
#
if(ENABLE_TSAN)
  #
  # -fsanitize=thread  - Build with tsan support
  #
  list(APPEND DEBUG_FSANITIZERFLAGS "thread")
  MESSAGE("ENABLING TSAN")
endif()

if(DEBUG_FSANITIZERFLAGS)
  string (REPLACE ";" "," DEBUG_FSANITIZERFLAGS "${DEBUG_FSANITIZERFLAGS}")
  set(CMAKE_C_FLAGS_DEBUG "-fsanitize=${DEBUG_FSANITIZERFLAGS} ${CMAKE_C_FLAGS_DEBUG}")
  set(CMAKE_LD_FLAGS_DEBUG "-fsanitize=${DEBUG_FSANITIZERFLAGS} ${CMAKE_LD_FLAGS_DEBUG}")
  MESSAGE("CMAKE_C_FLAGS_DEBUG are \"${CMAKE_C_FLAGS_DEBUG}\"")
  MESSAGE("CMAKE_LD_FLAGS_DEBUG are \"${CMAKE_LD_FLAGS_DEBUG}\"")
endif()

set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
set(THREADS_PREFER_PTHREAD_FLAG TRUE)
find_package(Threads REQUIRED)

include(CheckIncludeFiles)
include(CheckSymbolExists)
include(GNUInstallDirs)

check_include_files(sys/eventfd.h HAVE_SYS_EVENTFD_H)
check_include_files(sys/queue.h HAVE_SYS_QUEUE_H)
check_include_files(sys/signalfd.h HAVE_SYS_SIGNALFD_H)
check_include_files(sys/timerfd.h HAVE_SYS_TIMERFD_H)
check_include_files(sys/types.h HAVE_SYS_TYPES_H)
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
check_symbol_exists(SYS_pidfd_open sys/syscall.h HAVE_SYS_PIDFD_OPEN)

include_directories(${CMAKE_CURRENT_BINARY_DIR}
                    ${CMAKE_CURRENT_BINARY_DIR}/include)

set(LIBKQUEUE_HEADERS
    include/sys/event.h
    )

set(LIBKQUEUE_SOURCES
    src/common/alloc.h
    src/common/debug.c
    src/common/debug.h
    src/common/filter.c
    src/common/kevent.c
    src/common/knote.c
    src/common/kqueue.c
    src/common/libkqueue.c
    src/common/map.c
    src/common/private.h
    src/common/queue.h
    src/common/tree.h
    )

if(CMAKE_SYSTEM_NAME MATCHES Windows)
  list(APPEND LIBKQUEUE_SOURCES
       src/windows/platform.c
       src/windows/platform.h
       src/windows/read.c
       src/windows/stdint.h
       src/windows/timer.c
       src/windows/user.c
       )
elseif(CMAKE_SYSTEM_NAME MATCHES "(Solaris|SunOS)")
  list(APPEND LIBKQUEUE_SOURCES
       src/posix/eventfd.c
       src/posix/eventfd.h
       src/solaris/platform.c
       src/solaris/platform.h
       src/solaris/signal.c
       src/solaris/socket.c
       src/solaris/timer.c
       src/solaris/user.c
       )
elseif(CMAKE_SYSTEM_NAME STREQUAL Linux)
  check_include_files(linux/limits.h HAVE_LINUX_LIMITS_H)
  check_include_files(linux/sockios.h HAVE_LINUX_SOCKIOS_H)
  check_include_files(linux/unistd.h HAVE_LINUX_UNISTD_H)
  check_include_files(syscall.h HAVE_SYSCALL_H)

  #
  #  Set the default prefix to something sane
  #
  if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set (CMAKE_INSTALL_PREFIX "/usr" CACHE PATH "default install path" FORCE )
  endif()
  list(APPEND LIBKQUEUE_SOURCES
       src/linux/platform.c
       src/linux/platform.h
       src/linux/read.c
       src/linux/signal.c
       src/linux/timer.c
       src/linux/user.c
       src/linux/vnode.c
       src/linux/write.c
       )
    if (HAVE_SYS_PIDFD_OPEN)
        list(APPEND LIBKQUEUE_SOURCES src/linux/proc.c)
    else()
        list(APPEND LIBKQUEUE_SOURCES src/posix/proc.c)
    endif()
elseif(CMAKE_SYSTEM_NAME STREQUAL Emscripten)
  list(APPEND LIBKQUEUE_SOURCES
       src/posix/eventfd.c
       src/posix/eventfd.h
       src/posix/platform.c
       src/posix/platform.h
       src/posix/proc.c
       src/posix/read.c
       src/posix/signal.c
       src/posix/signal.c
       src/posix/timer.c
       src/posix/user.c
       src/posix/vnode.c
       src/posix/write.c
       )
else()
  message(FATAL_ERROR "unsupported host os")
endif()

source_group(includes
             FILES
               ${LIBKQUEUE_HEADERS})
source_group(src
             FILES
               ${LIBKQUEUE_SOURCES})

add_library(objlib OBJECT ${LIBKQUEUE_SOURCES} ${LIBKQUEUE_HEADERS})
add_library(kqueue SHARED $<TARGET_OBJECTS:objlib>)
add_library(kqueue_static STATIC $<TARGET_OBJECTS:objlib>)
if (CMAKE_SYSTEM_NAME MATCHES Windows)
  set_target_properties(kqueue_static
          PROPERTIES
          OUTPUT_NAME kqueue_static
          ARCHIVE_OUTPUT_DIRECTORY kqueueStatic)
else()
  set_target_properties(kqueue_static PROPERTIES OUTPUT_NAME kqueue)
endif()

# We should have absolute ABI compatibility between versions as none
# of the public function signatures of variables will change.
set_target_properties(kqueue PROPERTIES SOVERSION 0)

if(WIN32)
  target_compile_definitions(objlib PRIVATE _USRDLL;_WINDLL)
  target_compile_definitions(objlib PRIVATE _CRT_SECURE_NO_WARNINGS)
  target_compile_definitions(objlib PRIVATE WIN32_LEAN_AND_MEAN)
else()
  target_compile_definitions(objlib PRIVATE _XOPEN_SOURCE=600)
endif()

target_include_directories(objlib PRIVATE include)
if(NOT WIN32)
  target_include_directories(objlib PRIVATE src/common)
endif()

if(CMAKE_C_COMPILER_ID MATCHES GNU)
  target_compile_options(objlib PRIVATE -Wall -Werror)
endif()
if(MINGW AND CMAKE_C_COMPILER_ID MATCHES GNU)
  #TODO: is it needed at all?
  if (CMAKE_SIZEOF_VOID_P EQUAL 4)
    target_compile_options(objlib PRIVATE -march=i486)
  elseif(CMAKE_SIZEOF_VOID_P EQUAL 8)
    target_compile_options(objlib PRIVATE -march=x86-64)
  endif ()
endif()

if(WIN32)
  target_link_libraries(kqueue PRIVATE ws2_32)
endif()


if(ENABLE_TESTING)
  add_subdirectory(test)
endif()

if(CMAKE_SYSTEM_NAME STREQUAL Emscripten)
  target_compile_options(objlib PRIVATE -pthread)
else()
  target_link_libraries(kqueue PRIVATE Threads::Threads)
endif()

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/config.h.in
               ${CMAKE_CURRENT_BINARY_DIR}/config.h)

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/libkqueue.pc.in"
               "${CMAKE_CURRENT_BINARY_DIR}/libkqueue.pc"
               @ONLY)

#
#  Avoid conflicts by not trying to create existing directories
#
set(CPACK_RPM_EXCLUDE_FROM_AUTO_FILELIST_ADDITION ${CMAKE_INSTALL_FULL_MANDIR}
                                                  ${CMAKE_INSTALL_FULL_MANDIR}/man2
                                                  ${CMAKE_INSTALL_FULL_INCLUDEDIR}/sys)

install(FILES
          "${CMAKE_SOURCE_DIR}/include/sys/event.h"
        DESTINATION
          "${CMAKE_INSTALL_FULL_INCLUDEDIR}/kqueue/sys"
        COMPONENT headers)
install(TARGETS
          kqueue kqueue_static
        DESTINATION
          "${CMAKE_INSTALL_FULL_LIBDIR}"
        COMPONENT libraries)
install(FILES
          "${CMAKE_SOURCE_DIR}/kqueue.2"
        DESTINATION
          "${CMAKE_INSTALL_FULL_MANDIR}/man2"
        COMPONENT man)
install(FILES
          "${CMAKE_BINARY_DIR}/libkqueue.pc"
        DESTINATION
          "${CMAKE_INSTALL_FULL_LIBDIR}/pkgconfig"
        COMPONENT pkgconfig)

set(CPACK_PACKAGE_NAME ${PROJECT_NAME})
# CPACK_PACKAGE_VERSION is set automatically
set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})

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

if (PROJECT_VERSION_RELEASE)
set(CPACK_RPM_PACKAGE_RELEASE ${PROJECT_VERSION_RELEASE})
endif()

#
#  DEB Specific configuration
#
set(CPACK_DEBIAN_MAIN_PACKAGE_NAME "${CPACK_PACKAGE_NAME}")
set(CPACK_DEBIAN_MAIN_PACKAGE_SECTION "libs")

set(CPACK_DEBIAN_DEVEL_PACKAGE_NAME "${CPACK_PACKAGE_NAME}-dev")
set(CPACK_DEBIAN_DEVEL_PACKAGE_SECTION "libdevel")

set(CPACK_DEB_COMPONENT_INSTALL ON)             # Enable component based packaging (generate multiple packages)
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)         # Use default Debian package naming scheme
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
set(CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS ON)

#
#  We need to setup the package dependencies manually
#  when we're using a release version to ensure the
#  library package is in sync with the headers.
#
if (PROJECT_VERSION_RELEASE)
set(CPACK_DEBIAN_DEVEL_PACKAGE_DEPENDS "${CPACK_PACKAGE_NAME} (= ${PROJECT_VERSION}-${PROJECT_VERSION_RELEASE})")
set(CPACK_DEBIAN_PACKAGE_RELEASE ${PROJECT_VERSION_RELEASE})
else()
set(CPACK_DEBIAN_DEVEL_PACKAGE_DEPENDS "${CPACK_PACKAGE_NAME} (= ${PROJECT_VERSION})")
endif()

set(CPACK_SOURCE_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${PROJECT_VERSION}")
set(CPACK_SOURCE_IGNORE_FILES
  "cmake-build-*"
  ".github/"
  ".git/"
  ".*.swp"
)
set(CPACK_SOURCE_GENERATOR "TXZ")

set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Mark Heily <mark@heily.com>")
set(CPACK_DEBIAN_PACKAGE_HOMEPAGE "https://github.com/mheily/libkqueue")
include(CPack)

#
#  Ensure variables which represent arguments are not
#  cached. This provides more of a sane interface where
#  cmake will build with the arguments you last specified
#  not all the arguments provided since the beginning of
#  the lifetime of CMakeCache.txt.
#
unset(ENABLE_ASAN CACHE)
unset(ENABLE_LSAN CACHE)
unset(ENABLE_UBSAN CACHE)
unset(ENABLE_TSAN CACHE)
