#!/bin/sh

SRCCONF=${WORKSPACE}/`dirname $0`/src.conf

env \
	JFLAG=${BUILDER_JFLAG} \
	SRCCONF=${SRCCONF} \
	TARGET=mips \
	TARGET_ARCH=mips64 \
	CROSS_TOOLCHAIN=mips64-gcc6 \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
