#!/bin/sh

WORKSPACE=/workspace

export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
rm -fr ${MAKEOBJDIRPREFIX}

MAKECONF=/dev/null
SRCCONF=/dev/null

cd ${WORKSPACE}/src/sys/${TARGET}/conf
make LINT

cd ${WORKSPACE}/src
make \
	-DNO_CLEAN \
	-DTARGET=${TARGET} \
        buildkernel \
	KERNCONF=LINT \
        __MAKE_CONF=${MAKECONF} \
        SRCCONF=${SRCCONF}
