#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=sparc64 \
	TARGET_ARCH=sparc64 \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
