#!/bin/sh

IMAGE_NAME=riscv.img
JOB_BASE=${WORKSPACE}/freebsd-ci/jobs/${JOB_NAME}

TARGET=riscv
TARGET_ARCH=riscv64

export MAKEOBJDIRPREFIX=/tmp/obj
rm -fr ${MAKEOBJDIRPREFIX}
export DESTDIR=/tmp/dest
rm -fr ${DESTDIR}

MAKECONF=${MAKECONF:-/dev/null}
SRCCONF=${SRCCONF:-/dev/null}

cd ${WORKSPACE}/src

make -j ${BUILDER_JFLAG} \
	-DNO_CLEAN \
	CROSS_TOOLCHAIN=riscv64-gcc \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	buildworld

make CROSS_TOOLCHAIN=riscv64-gcc \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	-DNO_CLEAN \
	-DNO_ROOT \
	-DWITHOUT_TESTS \
	-DDB_FROM_SRC \
	DESTDIR=${DESTDIR} \
	installworld
make CROSS_TOOLCHAIN=riscv64-gcc \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	-DNO_CLEAN \
	-DNO_ROOT \
	-DWITHOUT_TESTS \
	DESTDIR=${DESTDIR} \
	distribution

cd ${WORKSPACE}
dd if=/dev/random of=${DESTDIR}/boot/entropy bs=4k count=1
src/tools/tools/makeroot/makeroot.sh -s 32m -f ${JOB_BASE}/basic.files ${IMAGE_NAME} ${DESTDIR}

cd ${WORKSPACE}/src
cat ${JOB_BASE}/RISCVTEST | sed -e "s,%%MFS_IMAGE%%,${WORKSPACE}/${IMAGE_NAME}," | tee sys/riscv/conf/RISCVTEST
make -j ${BUILDER_JFLAG} \
	-DNO_CLEAN \
	CROSS_TOOLCHAIN=riscv64-gcc \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	KERNCONF=RISCVTEST \
	MODULES_OVERRIDE='' \
	WITHOUT_FORMAT_EXTENSIONS=yes \
	buildkernel

cd ${WORKSPACE}
ARTIFACT_DEST=artifact/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
rm -fr ${WORKSPACE}/artifact
mkdir -p ${ARTIFACT_DEST}

xz ${IMAGE_NAME}
mv ${IMAGE_NAME}.xz ${ARTIFACT_DEST}

KERNEL_FILE=${MAKEOBJDIRPREFIX}${WORKSPACE}/src/${TARGET}.${TARGET_ARCH}/sys/RISCVTEST/kernel
xz ${KERNEL_FILE}
mv ${KERNEL_FILE}.xz ${ARTIFACT_DEST}

echo "r${SVN_REVISION}" > ${ARTIFACT_DEST}/revision.txt

echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
