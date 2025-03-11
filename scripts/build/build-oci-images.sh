#!/bin/sh

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

set -ex

if [ -z "${GIT_COMMIT}" ]; then
	echo "No git commit id specified"
	exit 1
fi

ARTIFACT_SERVER=${ARTIFACT_SERVER:-artifact.ci.freebsd.org}
ARTIFACT_SUBDIR=${FBSD_BRANCH}/${GIT_COMMIT}/${TARGET}/${TARGET_ARCH}

sudo chflags -R noschg work
sudo rm -fr work
mkdir -p work
cd work

# Initialize empty OCI image
umoci init --layout freebsd
umoci new --image freebsd:${GIT_COMMIT}

# Temporarily set OS to Linux to workaround a bug: https://github.com/opencontainers/umoci/issues/364
umoci config --image freebsd:${GIT_COMMIT} --os linux

# Extract bundle
sudo umoci unpack --image freebsd:${GIT_COMMIT} oci-bundle

DIST_PACKAGES="base"
if [ "${WITH_DOC}" = 1 ]; then
	DIST_PACKAGES="${DIST_PACKAGES} doc"
fi
if [ "${WITH_TESTS}" = 1 ]; then
	DIST_PACKAGES="${DIST_PACKAGES} tests"
fi
if [ "${WITH_DEBUG}" = 1 ]; then
	DIST_PACKAGES="${DIST_PACKAGES} base-dbg"
fi
if [ "${WITH_LIB32}" = 1 ]; then
	DIST_PACKAGES="${DIST_PACKAGES} lib32"
	if [ "${WITH_DEBUG}" = 1 ]; then
		DIST_PACKAGES="${DIST_PACKAGES} lib32-dbg"
	fi
fi

for f in ${DIST_PACKAGES}
do
	fetch https://${ARTIFACT_SERVER}/snapshot/${ARTIFACT_SUBDIR}/${f}.txz
	sudo tar Jxf ${f}.txz -C oci-bundle/rootfs
done

sudo umoci repack --image freebsd:${GIT_COMMIT} oci-bundle
sudo umoci config --image freebsd:${GIT_COMMIT} --os freebsd --author="FreeBSD Project" --architecture ${TARGET_ARCH}

sudo skopeo inspect oci:freebsd

cd ${WORKSPACE}
rm -fr artifact
mkdir -p artifact/${ARTIFACT_SUBDIR}
mv work/freebsd artifact/${ARTIFACT_SUBDIR}
