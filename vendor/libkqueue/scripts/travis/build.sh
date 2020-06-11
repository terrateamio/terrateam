#!/bin/bash -e
# Author: Jorge Pereira <jpereira@freeradius.org>
#

function fatal() {
    echo "$0: ERROR: $@"
    exit 1
}

if [[ ! "${BUILD_TYPE}" =~ Debug|Release ]]; then
    fatal "The 'BUILD_TYPE' should be 'Debug' or 'Release'."
fi

if ! cmake . -G "Unix Makefiles" \
    -DCMAKE_INSTALL_PREFIX="/usr" \
    -DCMAKE_INSTALL_LIBDIR="lib"  \
    -DCMAKE_VERBOSE_MAKEFILE:BOOL="ON" \
    -DENABLE_TESTING="YES" \
    -DENABLE_ASAN="${ENABLE_ASAN:-NO}" \
    -DENABLE_LSAN="${ENABLE_LSAN:-NO}" \
    -DENABLE_UBSAN="${ENABLE_UBSAN:-NO}" \
    -DCMAKE_BUILD_TYPE="${BUILD_TYPE}"; then
    fatal "Failed during cmake build configuration"
fi

#
#  Build the libkqueue
#
echo "Starting compilation"
if ! make -j8; then
    fatal "Failed during compilation"
fi

#
#  Build the *.deb packages
#
if ! cpack -G DEB; then
    fatal "Failed when building debian packages"
fi
