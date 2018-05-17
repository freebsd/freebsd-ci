#!/bin/sh

export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
rm -fr ${MAKEOBJDIRPREFIX}

MAKECONF=/dev/null
SRCCONF=/dev/null

cd ${WORKSPACE}/src/sys/${TARGET}/conf
make LINT

cd ${WORKSPACE}/src
make -j ${JFLAG} \
	-DNO_CLEAN \
	-DTARGET=${TARGET} \
	kernel-toolchain \
	buildkernel \
	KERNCONF=LINT \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF} \
	${EXTRA_FLAGS}
