#!/bin/sh

export TARGET=mips
export TARGET_ARCH=mips64
export USE_QEMU=1
export QEMU_ARCH="mips64"
export QEMU_MACHINE="malta"

# XXX: The MALTA64 config doesn't support neither AHCI nor virtio.
export QEMU_EXTRA_PARAM="-kernel kernel -drive if=none,file=disk-test.img,format=raw,id=hd2 -device ide-hd,bus=ide.0,drive=hd2 -drive if=none,file=meta.tar,format=raw,id=hd3 -device ide-hd,bus=ide.1,drive=hd3"

# XXX: Temporary, to compare performance results.
export VM_CPU_COUNT=1

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
