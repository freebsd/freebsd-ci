#!/bin/sh

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

TARGET=riscv
TARGET_ARCH=riscv64

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

ARTIFACT_SUBDIR=${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}

rm -f kernel.xz kernel
fetch https://artifact.ci.freebsd.org/snapshot/${ARTIFACT_SUBDIR}/kernel.xz
xz -d kernel.xz

rm -fr riscv-pk
git config --global http.proxy ${BUILDER_HTTP_PROXY}
git clone --depth=1 --single-branch https://github.com/freebsd-riscv/riscv-pk

mkdir riscv-pk/build/
cd riscv-pk/build/
git rev-parse HEAD

export CFLAGS="-nostdlib"
../configure --host=riscv64-unknown-freebsd11.0 --with-payload=${WORKSPACE}/kernel
gmake LIBS=''

xz bbl

cd ${WORKSPACE}
ARTIFACT_DEST=artifact/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
mkdir -p ${ARTIFACT_DEST}
mv riscv-pk/build/bbl.xz ${ARTIFACT_DEST}

echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
