#!/bin/sh

export TARGET=arm64
export TARGET_ARCH=aarch64
export USE_QEMU=1
export QEMU_ARCH="aarch64"
export QEMU_MACHINE="virt"
# XXX: U-Boot gets confused with two virtio drives.
export QEMU_DEVICES="-device virtio-blk,drive=hd0 -device ahci,id=ahci -device ide-hd,drive=hd1,bus=ahci.0"
export QEMU_EXTRA_PARAM="-bios /usr/local/share/u-boot/u-boot-qemu-arm64/u-boot.bin -cpu cortex-a57"

# XXX: Temporary, to compare performance results.
export VM_CPU_COUNT=1

export USE_TEST_SUBR="
disable-disks-tests.sh
disable-dtrace-tests.sh
disable-zfs-tests.sh
disable-notyet-tests.sh
run-kyua.sh
"

sh -x freebsd-ci/scripts/test/run-tests.sh

# Turn known test failures into xfails.
while read t; do xml ed -P -L -r "/testsuite/testcase[@classname=\"$t\"]/error" -v skip test-result.xml; done < xfail-list
