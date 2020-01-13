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
ARTIFACT_DEST=artifact/${ARTIFACT_SUBDIR}

cd ${WORKSPACE}

sudo rm -fr base || true
sudo chflags -R noschg base || true
sudo rm -fr base
fetch ${ARTIFACT_SERVER}/${ARTIFACT_SUBDIR}/base.txz
mkdir base
sudo tar Jxf base.txz -C base

sudo cp ${JOB_BASE}/files/fstab base/etc/
sudo cp ${JOB_BASE}/files/rc.conf base/etc/
sudo pwd_mkdb -d base/etc/ -p base/etc/master.passwd
sudo dd if=/dev/random of=base/boot/entropy bs=4k count=1

sudo rm -f riscv.img riscv.img.xz
sudo makefs -D -f 200000 -s 2g -o version=2 -Z riscv.img base
xz -0 riscv.img

rm -fr artifact
mkdir -p ${ARTIFACT_DEST}
mv riscv.img.xz ${ARTIFACT_DEST}

echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
