#!/bin/sh

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

JOB_BASE=${WORKSPACE}/freebsd-ci/jobs/${JOB_NAME}

TARGET=riscv
TARGET_ARCH=riscv64

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

ARTIFACT_SUBDIR=${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}

rm -f riscv.img.xz
fetch https://artifact.ci.freebsd.org/snapshot/${ARTIFACT_SUBDIR}/riscv.img.xz
rm -f kernel kernel.bin kernel.txz
fetch https://artifact.ci.freebsd.org/snapshot/${ARTIFACT_SUBDIR}/kernel.txz

xz -d riscv.img.xz

tar Jxvf kernel.txz --strip-components 3 boot/kernel/kernel
objcopy -S -O binary kernel kernel.bin

/usr/local/bin/python ${JOB_BASE}/test-in-qemu.py
