#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=powerpc \
	TARGET_ARCH=powerpc64 \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel.sh
