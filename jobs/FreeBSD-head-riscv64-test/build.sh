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

rm -f bbl-qemu.xz bbl-qemu
fetch https://artifact.ci.freebsd.org/snapshot/${ARTIFACT_SUBDIR}/bbl-qemu.xz
xz -d bbl-qemu.xz

python ${JOB_BASE}/test-in-qemu.py
