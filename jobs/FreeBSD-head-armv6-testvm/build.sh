#!/bin/sh

# XXX: This is currently broken: I couldn't find a kernel/u-boot/qemu
#      combination that actually works for armv6. -- trasz@

export JFLAG=${BUILDER_JFLAG}

export TARGET=arm
export TARGET_ARCH=armv6

export WITH_LIB32=0
export WITH_DEBUG=1
export WITH_TESTS=1

sh -x freebsd-ci/scripts/build/build-test_image-head.sh
