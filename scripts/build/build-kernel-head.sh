#!/bin/sh

set -ex

export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
rm -fr ${MAKEOBJDIRPREFIX}

MAKECONF=${MAKECONF:-/dev/null}
SRCCONF=${SRCCONF:-/dev/null}

cd /usr/src

if [ -n "${CROSS_TOOLCHAIN}" ]; then
	CROSS_TOOLCHAIN_PARAM=CROSS_TOOLCHAIN=${CROSS_TOOLCHAIN}
fi

sudo make -j ${JFLAG} -DNO_CLEAN \
	kernel-toolchain \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	${CROSS_TOOLCHAIN_PARAM} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF} \

sudo make -j ${JFLAG} -DNO_CLEAN \
	buildkernel \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	${CROSS_TOOLCHAIN_PARAM} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}

cd /usr/src/release

sudo make clean
sudo make -DNOPORTS -DNOSRC -DNODOC kernel.txz \
	TARGET=${TARGET} TARGET_ARCH=${TARGET_ARCH} \
	MAKE="make -DDB_FROM_SRC __MAKE_CONF=${MAKECONF} SRCCONF=${SRCCONF}"

if [ -f ${MAKECONF} ]; then
KERNCONF=$(make -f ${MAKECONF} -V KERNCONF)
fi
KERNCONF=${KERNCONF:-GENERIC}
ARTIFACT_DEST=artifact/${FBSD_BRANCH}/${GIT_COMMIT}/${TARGET}/${TARGET_ARCH}
if [ "${KERNCONF}" != "GENERIC" ]; then
	ARTIFACT_SUFFIX="-${KERNCONF}"
fi
sudo mkdir -p ${ARTIFACT_DEST}

ARTIFACT_OBJDIR=/usr/obj/usr/src/${TARGET}.${TARGET_ARCH}/release
for f in `ls ${ARTIFACT_OBJDIR}/*.txz ${ARTIFACT_OBJDIR}/MANIFEST`; do
	fb=$(basename ${f})
	fn=${fb%.*}
	fe=${fb##*.}
	if [ "${fn}" != "${fe}" ]; then
		fnew=${fn}${ARTIFACT_SUFFIX}.${fe}
	else
		fnew=${fb}${ARTIFACT_SUFFIX}
	fi
	sudo mv ${f} ${ARTIFACT_DEST}/${fnew}
done

echo "${GIT_COMMIT}" | sudo tee ${ARTIFACT_DEST}/revision.txt

echo "USE_GIT_COMMIT=${GIT_COMMIT}" > ${WORKSPACE}/trigger.property
