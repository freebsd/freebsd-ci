#!/bin/sh

JFLAG=${BUILDER_JFLAG}
TARGET=amd64
TARGET_ARCH=amd64
SRCCONF=${WORKSPACE}/`dirname $0`/src.conf

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

ARTIFACT_SERVER=${ARTIFACT_SERVER:-https://artifact.ci.freebsd.org}
ARTIFACT_SUBDIR=snapshot/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}

set +e
LAST_SVN_REVISION=$(fetch -q -o - https://ci-dev.freebsd.org/job/FreeBSD-head-amd64-build_inc/lastStableBuild/api/json | jq  '.changeSet.revisions[0].revision')
if [ -n "${LAST_SVN_REVISION}" ]; then
	LAST_ARTIFACT_SUBDIR=snapshot/${FBSD_BRANCH}/r${LAST_SVN_REVISION}/${TARGET}/${TARGET_ARCH}
	fetch ${ARTIFACT_SERVER}/${LAST_ARTIFACT_SUBDIR}/obj.tar.zst
	zstd -d -c obj.tar.zst | sudo tar xf -C /
fi
set -e

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

ARTIFACT_DEST=artifact/${ARTIFACT_SUBDIR}
sudo mkdir -p ${ARTIFACT_DEST}
sudo sh -c "tar -cf - --exclude .svn /usr/src | zstd -T${JFLAG} -c > ${ARTIFACT_DEST}/src.tar.zst"
# TODO: cleanup unneeded obj
sudo sh -c "tar -cf - /usr/obj | zstd -T${JFLAG} -c > ${ARTIFACT_DEST}/obj.tar.zst"
sudo mv /usr/obj/usr/src/${TARGET}.${TARGET_ARCH}/release/*.txz ${ARTIFACT_DEST}
sudo mv /usr/obj/usr/src/${TARGET}.${TARGET_ARCH}/release/MANIFEST ${ARTIFACT_DEST}

echo "r${SVN_REVISION}" | sudo tee ${ARTIFACT_DEST}/revision.txt

echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
