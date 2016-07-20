#!/bin/sh

JFLAG=${BUILDER_JFLAG}
TARGET=amd64

WORKSPACE=/workspace

export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
rm -fr ${MAKEOBJDIRPREFIX}

MAKECONF=/dev/null
SRCCONF=/dev/null

DISTDIR=${WORKSPACE}/dist

cd ${WORKSPACE}/src

make -j ${JFLAG} -DNO_CLEAN \
       buildworld \
       __MAKE_CONF=${MAKECONF} \
       SRCCONF=${SRCCONF}
make -j ${JFLAG} -DNO_CLEAN \
       buildkernel \
       __MAKE_CONF=${MAKECONF} \
       SRCCONF=${SRCCONF}

sudo make -DNO_CLEAN \
        -DNO_ROOT \
        distributeworld \
        __MAKE_CONF=${MAKECONF} \
        SRCCONF=${SRCCONF} \
        DISTDIR=${DISTDIR}
sudo make -DNO_CLEAN \
       -DNO_ROOT \
       packageworld \
       __MAKE_CONF=${MAKECONF} \
       SRCCONF=${SRCCONF} \
       DISTDIR=${DISTDIR}
sudo make -DNO_CLEAN \
       -DNO_ROOT \
       distributekernel \
       __MAKE_CONF=${MAKECONF} \
       SRCCONF=${SRCCONF} \
       DISTDIR=${DISTDIR}
sudo make -DNO_CLEAN \
       -DNO_ROOT \
       packagekernel \
       __MAKE_CONF=${MAKECONF} \
       SRCCONF=${SRCCONF} \
       DISTDIR=${DISTDIR}
