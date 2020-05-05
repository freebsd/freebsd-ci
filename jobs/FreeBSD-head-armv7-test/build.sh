#!/bin/sh

export TARGET=arm
export TARGET_ARCH=armv7
export USE_QEMU=1
export QEMU_ARCH="arm"
export QEMU_MACHINE="virt"
export QEMU_EXTRA_PARAM="-bios /usr/local/share/u-boot/u-boot-qemu-arm/u-boot.bin"

# U-Boot hangs with 4G.
export VM_MEM_SIZE="3g"

# XXX: Temporary, to compare performance results.
export VM_CPU_COUNT=1

export USE_TEST_SUBR="
disable-dtrace-tests.sh
disable-zfs-tests.sh
disable-notyet-tests.sh
run-kyua.sh
"

sh -x freebsd-ci/scripts/test/run-tests.sh
