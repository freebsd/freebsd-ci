#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=sparc64 \
	TARGET_ARCH=sparc64 \
	CROSS_TOOLCHAIN=sparc64-gcc6 \
	sh -ex ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
