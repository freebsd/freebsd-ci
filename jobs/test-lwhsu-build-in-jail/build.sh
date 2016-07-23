#!/bin/sh

JFLAG=${BUILDER_JFLAG}
TARGET_ARCH=aarch64
TARGET=arm64

MAKECONF=/dev/null
SRCCONF=/dev/null

cd /usr/src

sudo make -j ${JFLAG} -DNO_CLEAN \
	buildworld \
	TARGET_ARCH=${TARGET_ARCH} \
	TARGET=${TARGET} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}
sudo make -j ${JFLAG} -DNO_CLEAN \
	buildkernel \
	TARGET_ARCH=${TARGET_ARCH} \
	TARGET=${TARGET} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}

cd /usr/src/release

sudo make -DNOPORTS -DNOSRC -DNODOC ftp TARGET_ARCH=${TARGET_ARCH} TARGET=${TARGET}
SVN_REVISION=`svnliteversion /usr/src`
sudo mkdir -p artifact/${FBSD_BRANCH}/${SVN_REVISION}/${TARGET_ARCH}/${TARGET}
sudo mv ftp/* artifact/${FBSD_BRANCH}/${SVN_REVISION}/${TARGET_ARCH}/${TARGET}
