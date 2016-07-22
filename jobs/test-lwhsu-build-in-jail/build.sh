#!/bin/sh

JFLAG=${BUILDER_JFLAG}
TARGET=amd64

MAKECONF=/dev/null
SRCCONF=/dev/null

cd /usr/src

sudo make -j ${JFLAG} -DNO_CLEAN \
       buildworld \
       TARGET=${TARGET} \
       __MAKE_CONF=${MAKECONF} \
       SRCCONF=${SRCCONF}
sudo make -j ${JFLAG} -DNO_CLEAN \
       buildkernel \
       TARGET=${TARGET} \
       __MAKE_CONF=${MAKECONF} \
       SRCCONF=${SRCCONF}

cd /usr/src/release

sudo make -DNOPORTS -DNOSRC -DNODOC ftp TARGET=${TARGET}
SRC_REVISION=`svnliteversion /usr/src`
sudo mkdir artifact
sudo mv ftp artifact/${SRC_REVISION}
