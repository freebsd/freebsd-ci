#!/bin/sh

set -ex

export TESTTYPE=uid
. ${WORKSPACE}/freebsd-ci/scripts/build/build-reproducible-pre.sh
export TARGET=amd64
export TARGET_ARCH=amd64

echo $SOURCE_DATE_EPOCH
echo $SOURCE_DATE_EPOCH_BASE
cd /usr/src
sudo -u root -E make -j ${JFLAG} \
	buildworld \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	${CROSS_TOOLCHAIN_PARAM} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}
sudo -u root -E make -j ${JFLAG} -DNO_CLEAN -DNO_ROOT \
	buildkernel \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	${CROSS_TOOLCHAIN_PARAM} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}
export MAKEOBJDIRPREFIX=${WORKSPACE}/objtest
rm -fr ${MAKEOBJDIRPREFIX}
sudo -u nobody -E make -j ${JFLAG} \
	buildworld \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	${CROSS_TOOLCHAIN_PARAM} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}
sudo -u nobody -E make -j ${JFLAG} \
	buildkernel \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	${CROSS_TOOLCHAIN_PARAM} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}

. ${WORKSPACE}/freebsd-ci/scripts/build/build-reproducible.sh
