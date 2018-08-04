#!/bin/sh

export MAKEOBJDIRPREFIX=/tmp/obj
rm -fr ${MAKEOBJDIRPREFIX}

MAKECONF=/dev/null
SRCCONF=/dev/null

cd ${WORKSPACE}/src

make -DNO_CLEAN \
	buildLINT \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}

make -j ${JFLAG} -DNO_CLEAN \
	kernel-toolchain \
	KERNCONF=LINT \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF} \
	${EXTRA_FLAGS}

make -j ${JFLAG} -DNO_CLEAN \
	buildkernel \
	KERNCONF=LINT \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF} \
	${EXTRA_FLAGS}
