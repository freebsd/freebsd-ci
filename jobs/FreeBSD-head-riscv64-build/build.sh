#!/bin/sh

IMAGE_NAME=riscv.img
JOB_BASE=${WORKSPACE}/freebsd-ci/jobs/${JOB_NAME}

export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
rm -fr ${MAKEOBJDIRPREFIX}
export DESTDIR=${WORKSPACE}/dest
rm -fr ${DESTDIR}

MAKECONF=${MAKECONF:-/dev/null}
SRCCONF=${SRCCONF:-/dev/null}

cd ${WORKSPACE}/src

make -j ${BUILDER_JFLAG} \
	-DNO_CLEAN \
	CROSS_TOOLCHAIN=riscv64-gcc \
	TARGET=riscv \
	TARGET_ARCH=riscv64 \
	WITHOUT_FORMAT_EXTENSIONS=yes \
	buildworld

make CROSS_TOOLCHAIN=riscv64-gcc \
	TARGET=riscv \
	TARGET_ARCH=riscv64 \
	-DNO_CLEAN \
	-DNO_ROOT \
	-DWITHOUT_TESTS \
	DESTDIR=${DESTDIR} \
	installworld
make CROSS_TOOLCHAIN=riscv64-gcc \
	TARGET=riscv \
	TARGET_ARCH=riscv64 \
	-DNO_CLEAN \
	-DNO_ROOT \
	-DWITHOUT_TESTS \
	DESTDIR=${DESTDIR} \
	distribution

cd ${WORKSPACE}
src/tools/tools/makeroot/makeroot.sh -s 32m -f ${JOB_BASE}/basic.files ${IMAGE_NAME} ${DESTDIR}

cat ${JOB_BASE}/QEMUTEST | sed -e "s,%%MFS_IMAGE%%,${WORKSPACE}/${IMAGE_NAME}," | tee src/sys/riscv/conf/QEMUTEST

cd ${WORKSPACE}/src
make -j ${BUILDER_JFLAG} \
	-DNO_CLEAN \
	CROSS_TOOLCHAIN=riscv64-gcc \
	TARGET=riscv \
	TARGET_ARCH=riscv64 \
	KERNCONF=QEMUTEST \
	MODULES_OVERRIDE='' \
	buildkernel

ARTIFACT_DEST=artifact/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
mkdir -p ${ARTIFACT_DEST}
cp ${IMAGE_NAME} ${ARTIFACT_DEST}
cp ${MAKEOBJDIRPREFIX}/${TARGET}.${TARGET_ARCH}${WORKSPACE}/src/sys/QEMUTEST/kernel ${ARTIFACT_DEST}

echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
