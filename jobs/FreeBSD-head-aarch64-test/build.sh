#!/bin/sh

export TARGET=arm64
export TARGET_ARCH=aarch64
export USE_QEMU=1
export QEMU_ARCH="aarch64"
export QEMU_MACHINE="virt"
# XXX: The -drive below is to workaround the fact that QEMU_EFI.fd cannot handle ahci.
#      This means we effectively pass root device twice.
export QEMU_EXTRA_PARAM="-bios QEMU_EFI.fd -cpu cortex-a57 -drive if=virtio,file=disk-test.img,format=raw"

export USE_TEST_SUBR="
disable-dtrace-tests.sh
disable-zfs-tests.sh
disable-notyet-tests.sh
run-kyua.sh
"

export HTTP_PROXY=${BUILDER_HTTP_PROXY}
fetch http://snapshots.linaro.org/components/kernel/leg-virt-tianocore-edk2-upstream/latest/QEMU-AARCH64/RELEASE_CLANG35/QEMU_EFI.fd

sh -x freebsd-ci/scripts/test/run-tests.sh
