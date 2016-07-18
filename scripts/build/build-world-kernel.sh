#!/bin/sh

export MAKEOBJDIRPREFIX=/workspace/obj
rm -fr ${MAKEOBJDIRPREFIX}

MAKECONF=/dev/null
SRCCONF=/dev/null

cd src

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
