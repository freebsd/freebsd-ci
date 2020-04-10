#!/bin/sh

# XXX: This is currently broken: I couldn't find a kernel/u-boot/qemu
#      combination that actually works for armv6. -- trasz@

export TARGET=arm
export TARGET_ARCH=armv6
export USE_QEMU=1
export QEMU_ARCH="arm"
export QEMU_MACHINE="virt"

export USE_TEST_SUBR="
disable-dtrace-tests.sh
disable-zfs-tests.sh
disable-notyet-tests.sh
run-kyua.sh
"

sh -x freebsd-ci/scripts/test/run-tests.sh
