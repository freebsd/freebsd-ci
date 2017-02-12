#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=i386 \
	TARGET_ARCH=i386 \
	MAKE_ARGS="XZ_CMD='xz -T 8'" \
	sh -x freebsd-ci/scripts/build/build-world-kernel.sh
