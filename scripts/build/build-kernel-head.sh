#!/bin/sh

set -ex

export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
rm -fr ${MAKEOBJDIRPREFIX}

KERNCONF=${KERNCONF:-GENERIC}
MAKECONF=${MAKECONF:-/dev/null}
SRCCONF=${SRCCONF:-/dev/null}

cd /usr/src

if [ -n "${CROSS_TOOLCHAIN}" ]; then
	CROSS_TOOLCHAIN_PARAM=CROSS_TOOLCHAIN=${CROSS_TOOLCHAIN}
fi

make -j ${JFLAG} -DNO_CLEAN \
	kernel-toolchain \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	${CROSS_TOOLCHAIN_PARAM} \
	KERNCONF=${KERNCONF} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF} \

sudo make -j ${JFLAG} -DNO_CLEAN \
	buildkernel \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	${CROSS_TOOLCHAIN_PARAM} \
	KERNCONF=${KERNCONF} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}

cd /usr/src/release

sudo make clean
sudo make -DNOPORTS -DNOSRC -DNODOC kernel.txz \
	TARGET=${TARGET} TARGET_ARCH=${TARGET_ARCH} \
	MAKE="make -DDB_FROM_SRC __MAKE_CONF=${MAKECONF} SRCCONF=${SRCCONF}"

ARTIFACT_DEST=artifact/${FBSD_BRANCH}/${GIT_COMMIT}/${TARGET}/${TARGET_ARCH}
sudo mkdir -p ${ARTIFACT_DEST}
sudo mv /usr/obj/usr/src/${TARGET}.${TARGET_ARCH}/release/kernel.txz ${ARTIFACT_DEST}/kernel-GENERIC-KASAN.txz
sudo mv /usr/obj/usr/src/${TARGET}.${TARGET_ARCH}/release/MANIFEST ${ARTIFACT_DEST}/MANIFEST.GENERIC-KASAN

echo "${GIT_COMMIT}" | sudo tee ${ARTIFACT_DEST}/revision.txt

echo "GIT_COMMIT=${GIT_COMMIT}" > ${WORKSPACE}/trigger.property
