#!/bin/sh

export TARGET=mips
export TARGET_ARCH=mips64
export USE_QEMU=1
export QEMU_ARCH="mips64"
export QEMU_MACHINE="malta"
# XXX: The MALTA64 config doesn't support neither AHCI nor virtio.
export QEMU_DEVICES="-device ide-hd,bus=ide.0,drive=hd0 -device ide-hd,bus=ide.1,drive=hd1"
export QEMU_EXTRA_PARAM="-kernel kernel"

# qemu-system-mips64: maximum 2048MB
export VM_MEM_SIZE="2G"

# XXX: Temporary, to compare performance results.
export VM_CPU_COUNT=1

export USE_TEST_SUBR="
disable-disks-tests.sh
disable-dtrace-tests.sh
disable-zfs-tests.sh
disable-notyet-tests.sh
run-kyua.sh
"

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt
ARTIFACT_SERVER=${ARTIFACT_SERVER:-artifact.ci.freebsd.org}
ARTIFACT_SUBDIR=snapshot/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}

rm -f kernel kernel.txz
fetch https://${ARTIFACT_SERVER}/${ARTIFACT_SUBDIR}/kernel.txz
tar Jxvf kernel.txz --strip-components 3 boot/kernel/kernel

sh -x freebsd-ci/scripts/test/run-tests.sh
