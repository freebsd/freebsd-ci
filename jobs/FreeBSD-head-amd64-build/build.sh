#!/bin/sh

WORKSAPCE=/workspace

cd /usr/src
patch < ${WORKSAPCE}/freebsd-ci/jobs/FreeBSD-head-amd64-build/keep-empty-files-in-dist.diff
cd -

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=amd64 \
	TARGET_ARCH=amd64 \
	sh -x ${WORKSAPCE}/freebsd-ci/scripts/build/build-world-kernel.sh
