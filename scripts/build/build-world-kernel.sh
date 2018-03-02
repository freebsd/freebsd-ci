#!/bin/sh

set -ex

export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
rm -fr ${MAKEOBJDIRPREFIX}

MAKECONF=${MAKECONF:-/dev/null}
SRCCONF=${SRCCONF:-/dev/null}

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

cd release
# Do note that release scripts on stable/11 are *not* RO-friendly
sudo make clean
sudo make -DNOPORTS -DNOSRC -DNODOC packagesystem \
	TARGET=${TARGET} TARGET_ARCH=${TARGET_ARCH} \
	MAKE="make __MAKE_CONF=${MAKECONF} SRCCONF=${SRCCONF}"

ARTIFACT_DEST=artifact/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
sudo mkdir -p ${ARTIFACT_DEST}
sudo mv *.txz MANIFEST ${ARTIFACT_DEST}

echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
