#!/bin/sh

JFLAG=${BUILDER_JFLAG}

TARGET=amd64
TARGET_ARCH=amd64

SRCCONF=/workspace/`dirname $0`/src.conf
MAKECONF=/workspace/`dirname $0`/make.conf

WORKSPACE=/workspace

export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
rm -fr ${MAKEOBJDIRPREFIX}

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

sudo make MAKE="make __MAKE_CONF=${MAKECONF} SRCCONF=${SRCCONF}" \
	-DNOPORTS -DNOSRC -DNODOC ftp TARGET=${TARGET} TARGET_ARCH=${TARGET_ARCH}

ARTIFACT_DEST=artifact/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
sudo mkdir -p ${ARTIFACT_DEST}
sudo mv ftp/* ${ARTIFACT_DEST}

echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
