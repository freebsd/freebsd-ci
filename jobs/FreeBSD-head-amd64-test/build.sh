#!/bin/sh

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

BRANCH=head
TARGET=amd64
TARGET_ARCH=amd64

ARTIFACT_SUBDIR=${BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}

fetch http://artifact.ci.freebsd.org/snapshot/${ARTIFACT_SUBDIR}/disk-test.img.xz
xz -d disk-test.img.xz

# run disk-test.img with bhyve

# extract test result
