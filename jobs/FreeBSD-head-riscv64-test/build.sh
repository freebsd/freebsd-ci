#!/bin/sh

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

set -ex

JOB_BASE=${WORKSPACE}/freebsd-ci/jobs/${JOB_NAME}

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

TARGET=riscv
TARGET_ARCH=riscv64

ARTIFACT_SERVER=${ARTIFACT_SERVER:-https://artifact.ci.freebsd.org}
ARTIFACT_SUBDIR=snapshot/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}

rm -f riscv.img riscv.img.xz
fetch ${ARTIFACT_SERVER}/${ARTIFACT_SUBDIR}/riscv.img.xz
rm -f kernel kernel.txz
fetch ${ARTIFACT_SERVER}/${ARTIFACT_SUBDIR}/kernel.txz

xz -d riscv.img.xz

tar Jxvf kernel.txz --strip-components 3 boot/kernel/kernel

/usr/local/bin/python ${JOB_BASE}/test-in-qemu.py
