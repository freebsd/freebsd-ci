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
ARTIFACT_DEST=${WORKSPACE}/artifact/${ARTIFACT_SUBDIR}
rm -fr ${WORKSPACE}/artifact
mkdir -p ${ARTIFACT_DEST}

cd ${WORKSPACE}
sudo rm -fr base || true
sudo chflags -R noschg base || true
sudo rm -fr base
fetch https://artifact.ci.freebsd.org/snapshot/${ARTIFACT_SUBDIR}/base.txz
mkdir base
sudo tar Jxf base.txz -C base

sudo cp ${JOB_BASE}/files/fstab base/etc/
sudo cp ${JOB_BASE}/files/rc.conf base/etc/
sudo pwd_mkdb -d base/etc/ -p base/etc/master.passwd
sudo dd if=/dev/random of=base/boot/entropy bs=4k count=1

sudo rm -f riscv.img riscv.img.xz
sudo makefs -D -f 200000 -s 2g -o version=2 -Z riscv.img base
xz -0 riscv.img
mv riscv.img.xz ${ARTIFACT_DEST}

cd ${WORKSPACE}
echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
