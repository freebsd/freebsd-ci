#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=sparc64 \
	TARGET_ARCH=sparc64 \
	sh -ex ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
