#!/bin/sh

export TARGET=riscv
export TARGET_ARCH=riscv64
export USE_QEMU=1
export QEMU_ARCH="riscv64"
export QEMU_MACHINE="virt"
# XXX: Note the virtio-blk-device instead of virtio-blk; kernel doesn't seem to support the latter.
export QEMU_DEVICES="-device virtio-blk-device,drive=hd0 -device virtio-blk-device,drive=hd1"
OPENSBI=/usr/local/share/opensbi/lp64/generic/firmware/fw_jump.elf
UBOOT=/usr/local/share/u-boot/u-boot-qemu-riscv64/u-boot.bin
export QEMU_EXTRA_PARAM="-bios $OPENSBI -kernel $UBOOT"

# XXX: Eventually panics with SMP.
export VM_CPU_COUNT=1

export USE_TEST_SUBR="
disable-disks-tests.sh
disable-dtrace-tests.sh
disable-zfs-tests.sh
disable-notyet-tests.sh
run-kyua.sh
"

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt
ARTIFACT_SERVER=${ARTIFACT_SERVER:-https://artifact.ci.freebsd.org}
ARTIFACT_SUBDIR=snapshot/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}

rm -f kernel kernel.txz
fetch ${ARTIFACT_SERVER}/${ARTIFACT_SUBDIR}/kernel.txz
tar Jxvf kernel.txz --strip-components 3 boot/kernel/kernel

sh -x freebsd-ci/scripts/test/run-tests.sh
