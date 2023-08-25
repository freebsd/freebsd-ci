#!/bin/sh

export JFLAG=${BUILDER_JFLAG}

export TARGET=riscv
export TARGET_ARCH=riscv64

export WITH_LIB32=0
export WITH_DEBUG=1
export WITH_TESTS=1

sh -x freebsd-ci/scripts/build/build-test_image-head.sh
