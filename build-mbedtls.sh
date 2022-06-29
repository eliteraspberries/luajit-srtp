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
    patch -f -p0 < ${dir}/patches/patch-mbedtls-${VERSION}.txt
) || true
cd mbedtls-${VERSION}

BUILD_ENV="SHARED=1"
case "${TARGET}" in
    *-*-android*)
        BUILD_ENV="${BUILD_ENV} SOEXT_CRYPTO=so"
        BUILD_ENV="${BUILD_ENV} SOEXT_TLS=so"
        BUILD_ENV="${BUILD_ENV} SOEXT_X509=so"
        ;;
    *)
        ;;
esac
make clean
env ${BUILD_ENV} make lib

export DESTDIR="${dir}/build/${TARGET}"
mkdir -p "${DESTDIR}"
make install DESTDIR="${DESTDIR}"
