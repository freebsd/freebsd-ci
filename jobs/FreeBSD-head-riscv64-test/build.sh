#!/bin/sh

export TARGET=riscv
export TARGET_ARCH=riscv64
export USE_QEMU=1
export QEMU_ARCH="riscv64"
export QEMU_MACHINE="virt"
export QEMU_EXTRA_PARAM="-bios /usr/local/share/opensbi/platform/qemu/virt/firmware/fw_jump.elf -kernel kernel"
export VM_USE_VIRTIO_BLK=1

export USE_TEST_SUBR="
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
