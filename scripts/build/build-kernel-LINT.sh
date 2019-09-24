#!/bin/sh

export MAKEOBJDIRPREFIX=/tmp/obj
rm -fr ${MAKEOBJDIRPREFIX}

MAKECONF=/dev/null
SRCCONF=/dev/null

KERNCONF=${KERNCONF:-LINT}

cd ${WORKSPACE}/src/sys/${TARGET}/conf
make LINT

cd ${WORKSPACE}/src

make -j ${JFLAG} \
	-DNO_CLEAN \
	-DTARGET=${TARGET} \
	kernel-toolchain \
	KERNCONF=${KERNCONF} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF} \
	${EXTRA_FLAGS}

make -j ${JFLAG} \
	-DNO_CLEAN \
	-DTARGET=${TARGET} \
	buildkernel \
	KERNCONF=${KERNCONF} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF} \
	${EXTRA_FLAGS}
