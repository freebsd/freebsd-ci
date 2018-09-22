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

cd /usr/src/release

sudo make clean
sudo make -DNOPORTS -DNOSRC -DNODOC packagesystem \
	TARGET=${TARGET} TARGET_ARCH=${TARGET_ARCH} \
	MAKE="make -DDB_FROM_SRC __MAKE_CONF=${MAKECONF} SRCCONF=${SRCCONF}"

ARTIFACT_DEST=artifact/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
sudo mkdir -p ${ARTIFACT_DEST}
tar -cf - --exclude .svn /usr/src | xz -T0 > ${ARTIFACT_DEST}/src.tar
tar -cf - /usr/obj | xz -T0 > ${ARTIFACT_DEST}/obj.tar
sudo mv /usr/obj/usr/src/${TARGET}.${TARGET_ARCH}/release/*.txz ${ARTIFACT_DEST}
sudo mv /usr/obj/usr/src/${TARGET}.${TARGET_ARCH}/release/MANIFEST ${ARTIFACT_DEST}

echo "r${SVN_REVISION}" | sudo tee ${ARTIFACT_DEST}/revision.txt

echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
