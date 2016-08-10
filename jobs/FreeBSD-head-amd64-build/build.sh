#!/bin/sh

cd /usr/src
patch < /workspace/freebsd-ci/jobs/FreeBSD-head-amd64-build/keep-empty-files-in-dist.diff

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=amd64 \
	TARGET_ARCH=amd64 \
	sh -x freebsd-ci/scripts/build/build-world-kernel.sh
