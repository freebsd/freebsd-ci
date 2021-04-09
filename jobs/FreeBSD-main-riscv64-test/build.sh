#!/bin/sh

export TARGET=riscv
export TARGET_ARCH=riscv64
export USE_QEMU=1
export QEMU_ARCH="riscv64"
export QEMU_MACHINE="virt"
# XXX: Note the virtio-blk-device instead of virtio-blk; kernel doesn't seem to support the latter.
export QEMU_DEVICES="-device virtio-blk-device,drive=hd0 -device virtio-blk-device,drive=hd1"
export QEMU_EXTRA_PARAM="-bios default -kernel kernel"

export USE_TEST_SUBR="
disable-disks-tests.sh
disable-dtrace-tests.sh
disable-zfs-tests.sh
disable-notyet-tests.sh
run-kyua.sh
"

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt
ARTIFACT_SERVER=${ARTIFACT_SERVER:-artifact.ci.freebsd.org}
ARTIFACT_SUBDIR=snapshot/${FBSD_BRANCH}/${GIT_COMMIT}/${TARGET}/${TARGET_ARCH}

rm -f kernel kernel.txz
fetch https://${ARTIFACT_SERVER}/${ARTIFACT_SUBDIR}/kernel.txz
tar Jxvf kernel.txz --strip-components 3 boot/kernel/kernel

sh -ex freebsd-ci/scripts/test/run-tests.sh
