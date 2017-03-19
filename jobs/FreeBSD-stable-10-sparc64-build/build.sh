#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=sparc64 \
	TARGET_ARCH=sparc64 \
	sh -x freebsd-ci/scripts/build/build-world-kernel.sh
