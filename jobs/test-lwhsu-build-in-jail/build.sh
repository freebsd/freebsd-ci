#!/bin/sh

JFLAG=${BUILDER_JFLAG}
TARGET=amd64

MAKECONF=/dev/null
SRCCONF=/dev/null

cd /usr/src

sudo make -j ${JFLAG} -DNO_CLEAN \
       buildworld \
       __MAKE_CONF=${MAKECONF} \
       SRCCONF=${SRCCONF}
sudo make -j ${JFLAG} -DNO_CLEAN \
       buildkernel \
       __MAKE_CONF=${MAKECONF} \
       SRCCONF=${SRCCONF}

sudo make -DNO_CLEAN \
        -DNO_ROOT \
        distributeworld \
        __MAKE_CONF=${MAKECONF} \
        SRCCONF=${SRCCONF} \
sudo make -DNO_CLEAN \
       -DNO_ROOT \
       packageworld \
       __MAKE_CONF=${MAKECONF} \
       SRCCONF=${SRCCONF} \
sudo make -DNO_CLEAN \
       -DNO_ROOT \
       distributekernel \
       __MAKE_CONF=${MAKECONF} \
       SRCCONF=${SRCCONF} \
sudo make -DNO_CLEAN \
       -DNO_ROOT \
       packagekernel \
       __MAKE_CONF=${MAKECONF} \
       SRCCONF=${SRCCONF} \
