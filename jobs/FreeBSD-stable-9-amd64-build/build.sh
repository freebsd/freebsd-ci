#!/bin/sh

export MAKEOBJDIRPREFIX=/workspace/obj
rm -fr ${MAKEOBJDIRPREFIX}

MAKECONF=/dev/null
SRCCONF=/dev/null

cd src

make -j ${BUILDER_JFLAG} -DNO_CLEAN \
        buildworld \
       __MAKE_CONF=${MAKECONF} \
       SRCCONF=${SRCCONF}
make -j ${BUILDER_JFLAG} -DNO_CLEAN \
        buildkernel \
        __MAKE_CONF=${MAKECONF} \
        SRCCONF=${SRCCONF}
