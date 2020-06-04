#!/bin/sh

export TARGET=powerpc
export TARGET_ARCH=powerpc64
export USE_QEMU=1
export QEMU_ARCH="ppc64"
# The cap-hpt-max-page-size is to get rid of the "mmu_phyp: Support for hugepages not found"
# warning on boot.  It's expected to improve performance.
export QEMU_MACHINE="pseries,cap-hpt-max-page-size=16M"
# XXX: Note the reversed order; otherwise the metadisk would end up as vtbd0
export QEMU_DEVICES="-device virtio-blk,drive=hd1 -device virtio-blk,drive=hd0"
# The -accel tcg,thread=multi is supposed to improve performance.
export QEMU_EXTRA_PARAM="-vga none -accel tcg,thread=multi"

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
