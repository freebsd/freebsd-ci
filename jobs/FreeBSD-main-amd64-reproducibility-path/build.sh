#!/bin/sh

set -ex

export TESTTYPE=path
. ${WORKSPACE}/freebsd-ci/scripts/build/build-reproducible-pre.sh
export TARGET=amd64
export TARGET_ARCH=amd64

echo $SOURCE_DATE_EPOCH
echo $SOURCE_DATE_EPOCH_BASE
cp -Rp /usr/src ${WORKSPACE}/src1
cp -Rp /usr/src ${WORKSPACE}/src2
cd ${WORKSPACE}/src1
make -j ${JFLAG} -DNO_CLEAN \
	buildworld \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	${CROSS_TOOLCHAIN_PARAM} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}
make -j ${JFLAG} -DNO_CLEAN \
	buildkernel \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	${CROSS_TOOLCHAIN_PARAM} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}
export MAKEOBJDIRPREFIX=${WORKSPACE}/objtest
rm -fr ${MAKEOBJDIRPREFIX}
cd ${WORKSPACE}/src2
make -j ${JFLAG} -DNO_CLEAN \
	buildworld \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	${CROSS_TOOLCHAIN_PARAM} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}
make -j ${JFLAG} -DNO_CLEAN \
	buildkernel \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	${CROSS_TOOLCHAIN_PARAM} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}

. ${WORKSPACE}/freebsd-ci/scripts/build/build-reproducible.sh
