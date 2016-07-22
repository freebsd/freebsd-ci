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
sudo make -DNOPORTS -DNOSRC -DNODOC disc1.iso TARGET=${TARGET}
SRC_REVISION=`svnliteversion /usr/src`
sudo mkdir artifact
sudo mv ftp disc1.iso artifact/${SRC_REVISION}/${TARGET}
