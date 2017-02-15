#!/bin/sh

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

TARGET=riscv
TARGET_ARCH=riscv64

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

ARTIFACT_SUBDIR=${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
ARTIFACT_DEST=${WORKSPACE}/artifact/${ARTIFACT_SUBDIR}
mkdir -p ${ARTIFACT_DEST}

rm -fr riscv-pk
git config --global http.proxy ${BUILDER_HTTP_PROXY}
git clone --depth=1 --single-branch https://github.com/freebsd-riscv/riscv-pk
cd riscv-pk
git rev-parse HEAD

cd ${WORKSPACE}
rm -f kernel-qemu.xz kernel-qemu
fetch https://artifact.ci.freebsd.org/snapshot/${ARTIFACT_SUBDIR}/kernel-qemu.xz
xz -d kernel-qemu.xz

rm -fr riscv-pk/build/
mkdir riscv-pk/build/
cd riscv-pk/build/

export CFLAGS="-nostdlib"
../configure --host=riscv64-unknown-freebsd11.0 --with-payload=${WORKSPACE}/kernel-qemu
gmake LIBS=''

mv bbl bbl-qemu
xz bbl-qemu
mv bbl-qemu.xz ${ARTIFACT_DEST}

cd ${WORKSPACE}
rm -f kernel-spike.xz kernel-spike
fetch https://artifact.ci.freebsd.org/snapshot/${ARTIFACT_SUBDIR}/kernel-spike.xz
xz -d kernel-spike.xz

rm -fr riscv-pk/build/
mkdir riscv-pk/build/
cd riscv-pk/build/

export CFLAGS="-nostdlib"
../configure --host=riscv64-unknown-freebsd11.0 --with-payload=${WORKSPACE}/kernel-spike
gmake LIBS=''

mv bbl bbl-spike
xz bbl-spike
mv bbl-spike.xz ${ARTIFACT_DEST}

cd ${WORKSPACE}
echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
