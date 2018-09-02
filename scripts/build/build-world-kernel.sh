#!/bin/sh

set -ex

export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
rm -fr ${MAKEOBJDIRPREFIX}

MAKECONF=${MAKECONF:-/dev/null}
SRCCONF=${SRCCONF:-/dev/null}

# Mount source readonly
mkdir -p /usr/src.ro
mount -o ro -t nullfs /usr/src /usr/src.ro
# Set cleanup trap
trap "umount /usr/src.ro" exit

cd /usr/src.ro

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

# Re-mount it read/write to work around release scripts polluting src
cd /usr
umount /usr/src.ro
mount -t nullfs /usr/src /usr/src.ro
cd /usr/src.ro/release

sudo make clean
sudo make -DNOPORTS -DNOSRC -DNODOC packagesystem \
	TARGET=${TARGET} TARGET_ARCH=${TARGET_ARCH} \
	MAKE="make __MAKE_CONF=${MAKECONF} SRCCONF=${SRCCONF}"

ARTIFACT_DEST=artifact/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
sudo mkdir -p ${ARTIFACT_DEST}
sudo mv *.txz MANIFEST ${ARTIFACT_DEST}

echo "r${SVN_REVISION}" | sudo tee ${ARTIFACT_DEST}/revision.txt

echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
