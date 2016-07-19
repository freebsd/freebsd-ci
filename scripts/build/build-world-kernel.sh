#!/bin/sh

WORKSPACE=/workspace

export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
rm -fr ${MAKEOBJDIRPREFIX}

MAKECONF=/dev/null
SRCCONF=/dev/null

cd ${WORKSPACE}/src

make -j ${JFLAG} -DNO_CLEAN \
	-DTARGET=${TARGET} \
        buildworld \
       __MAKE_CONF=${MAKECONF} \
       SRCCONF=${SRCCONF}
make -j ${JFLAG} -DNO_CLEAN \
	-DTARGET=${TARGET} \
        buildkernel \
        __MAKE_CONF=${MAKECONF} \
        SRCCONF=${SRCCONF}
