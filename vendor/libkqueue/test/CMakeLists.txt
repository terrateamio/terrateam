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

set(LIBKQUEUE_TEST_SOURCES
    kevent.c
    main.c
    read.c
    test.c
    timer.c
    user.c
    vnode.c)
if(UNIX)
  list(APPEND LIBKQUEUE_TEST_SOURCES
       proc.c
       signal.c)
endif()

add_executable(libkqueue-test ${LIBKQUEUE_TEST_SOURCES})
target_include_directories(libkqueue-test
                           PRIVATE
                             "${CMAKE_SOURCE_DIR}"
                             "${CMAKE_SOURCE_DIR}/include")
if(WIN32)
  target_compile_definitions(libkqueue-test
                             PRIVATE
                               _CRT_SECURE_NO_WARNINGS
                               _CRT_NONSTDC_NO_WARNINGS
                               _WINSOCK_DEPRECATED_NO_WARNINGS)
  if(CMAKE_C_COMPILER_ID MATCHES Clang)
    target_compile_options(libkqueue-test PRIVATE -Wno-unused-variable)
  endif()
elseif(UNIX)
  target_link_libraries(libkqueue-test PRIVATE -rdynamic)
endif()

#
# Don't link against -lkqueue on OSX and FreeBSD
#
if(NOT "${CMAKE_SYSTEM_NAME}" MATCHES "(Darwin|FreeBSD)")
  target_link_libraries(libkqueue-test
                        PRIVATE
                        kqueue
                        Threads::Threads)
endif()

if(WIN32)
  target_link_libraries(libkqueue-test
                        PRIVATE
                          ws2_32)
endif()

add_test(NAME libkqueue-test
         COMMAND libkqueue-test)

