#!/bin/sh

set -e
set -x

dir="$(cd $(dirname $0) && pwd)"

TARGET="${TARGET:=$(${CC} ${CFLAGS} -dumpmachine | sed -e 's/[0-9.]*$//')}"

test -f build/${TARGET}/lib/libmbedtls.dylib && exit 0
test -f build/${TARGET}/lib/libmbedtls.so && exit 0

VERSION="${VERSION:=3.1.0}"
test -f mbedtls-${VERSION}.zip || \
    curl -L -o mbedtls-${VERSION}.zip \
    https://github.com/Mbed-TLS/mbedtls/archive/refs/tags/v${VERSION}.zip
test -d mbedtls-${VERSION} || \
    unzip mbedtls-${VERSION}.zip
(
    patch -f -p1 -d mbedtls-${VERSION} < ${dir}/patches/patch-mbedtls-3.1.0.txt
) || true

cd mbedtls-${VERSION}
make clean
make lib SHARED=1
export DESTDIR="${dir}/build/${TARGET}"
mkdir -p "${DESTDIR}"
make install DESTDIR="${DESTDIR}" SHARED=1
