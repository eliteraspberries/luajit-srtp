#!/bin/sh

set -e
set -x

dir="$(cd $(dirname $0) && pwd)"

AR="${AR:=ar}"
CC="${CC:=clang}"
LD="${LD:=${CC}}"

TARGET="${TARGET:=$(${CC} ${CFLAGS} -dumpmachine | sed -e 's/[0-9.]*$//')}"

test -f build/${TARGET}/lib/libsrtp2.dylib && exit 0
test -f build/${TARGET}/lib/libsrtp2.so && exit 0

DESTDIR="${dir}/build/${TARGET}"
PREFIX="${PREFIX:=/.}"

case "${TARGET}" in
    *-*-android*)
        AR="$(which ${AR})"
        CC="$(which ${CC})"
        LD="$(which ${LD})"
        ;;
    *-*-darwin*)
        AR="$(xcrun --sdk macosx --find ${AR})"
        CC="$(xcrun --sdk macosx --find ${CC})"
        LD="$(xcrun --sdk macosx --find ${LD})"
        ;;
    *-*-ios*)
        AR="$(xcrun --sdk iphoneos --find ${AR})"
        CC="$(xcrun --sdk iphoneos --find ${CC})"
        LD="$(xcrun --sdk iphoneos --find ${LD})"
        ;;
    *)
        ;;
esac
case "${CC}" in
    *clang)
        CFLAGS="--target=${TARGET} ${CFLAGS}"
        ;;
    *)
        ;;
esac
case "${TARGET}" in
    arm64-*-*)
        CMAKE_ARGS="-DCMAKE_SYSTEM_PROCESSOR=arm64 ${CMAKE_ARGS}"
        ;;
    arm-*-*)
        CMAKE_ARGS="-DCMAKE_SYSTEM_PROCESSOR=arm ${CMAKE_ARGS}"
        ;;
    x86_64-*-*)
        CMAKE_ARGS="-DCMAKE_SYSTEM_PROCESSOR=x86_64 ${CMAKE_ARGS}"
        ;;
    *)
        ;;
esac
case "${TARGET}" in
    *-*-darwin*)
        CMAKE_ARGS="-DCMAKE_SYSTEM_NAME=Darwin ${CMAKE_ARGS}"
        SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
        CMAKE_ARGS="-DCMAKE_SYSROOT=${SDKROOT} ${CMAKE_ARGS}"
        ;;
    *-*-ios*)
        CMAKE_ARGS="-DCMAKE_SYSTEM_NAME=iOS ${CMAKE_ARGS}"
        SDKROOT="$(xcrun --sdk iphoneos --show-sdk-path)"
        CMAKE_ARGS="-DCMAKE_SYSROOT=${SDKROOT} ${CMAKE_ARGS}"
        ;;
    *-*-android*)
        CMAKE_ARGS="-DCMAKE_SYSTEM_NAME=Linux ${CMAKE_ARGS}"
        ;;
    *)
        ;;
esac

VERSION="${VERSION:=2.4.2}"
test -f libsrtp-${VERSION}.zip || \
    curl -L -o libsrtp-${VERSION}.zip https://github.com/cisco/libsrtp/archive/refs/tags/v${VERSION}.zip
test -d libsrtp-${VERSION} || \
    unzip libsrtp-${VERSION}.zip
cd libsrtp-${VERSION}

CMAKE_ARGS="${CMAKE_ARGS} "
if test "${DEBUG}" = "0"; then
    CMAKE_ARGS="-DCMAKE_BUILD_TYPE=Release ${CMAKE_ARGS}"
else
    CMAKE_ARGS="-DCMAKE_BUILD_TYPE=Debug ${CMAKE_ARGS}"
    CMAKE_ARGS="-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON ${CMAKE_ARGS}"
fi
CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${PREFIX}"
CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_SYSTEM_PREFIX_PATH=${DESTDIR}"

CMAKE_ARGS="-DCMAKE_C_COMPILER_TARGET=${TARGET} ${CMAKE_ARGS}"

CMAKE_ARGS="${CMAKE_ARGS} -DENABLE_MBEDTLS=ON"
CMAKE_ARGS="${CMAKE_ARGS} -DENABLE_NSS=OFF"
CMAKE_ARGS="${CMAKE_ARGS} -DENABLE_OPENSSL=OFF"
CMAKE_ARGS="${CMAKE_ARGS} -DBUILD_WITH_SANITIZERS=OFF"
CMAKE_ARGS="${CMAKE_ARGS} -DBUILD_SHARED_LIBS=ON"

export AR
export CC
export LD
export CFLAGS="${CPPFLAGS} ${CFLAGS}"
export LDFLAGS

mkdir -p build
rm -rf build/*
cd build
cmake ${CMAKE_ARGS} ..
make
make install DESTDIR="${DESTDIR}"
