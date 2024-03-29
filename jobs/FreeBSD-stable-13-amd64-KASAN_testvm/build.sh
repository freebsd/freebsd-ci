#!/bin/sh

export JFLAG=${BUILDER_JFLAG}

export TARGET=amd64
export TARGET_ARCH=amd64

export WITH_LIB32=1
export WITH_DEBUG=1
export WITH_TESTS=1

export KERNCONF=GENERIC-KASAN

sh -x freebsd-ci/scripts/build/build-test_image-13.sh
