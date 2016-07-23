#!/bin/sh

JFLAG=${BUILDER_JFLAG}
TARGET_ARCH=i386
TARGET=i386

MAKECONF=/dev/null
SRCCONF=/dev/null

env; exit 0

cd /usr/src

sudo make -j ${JFLAG} -DNO_CLEAN \
	buildworld \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}
sudo make -j ${JFLAG} -DNO_CLEAN \
	buildkernel \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}

cd /usr/src/release

sudo make -DNOPORTS -DNOSRC -DNODOC ftp TARGET=${TARGET} TARGET_ARCH=${TARGET_ARCH}
sudo mkdir -p artifact/${FBSD_BRANCH}/${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
sudo mv ftp/* artifact/${FBSD_BRANCH}/${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
