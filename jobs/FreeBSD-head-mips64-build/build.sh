#!/bin/sh

SRCCONF=${WORKSPACE}/`dirname $0`/src.conf

env \
	JFLAG=${BUILDER_JFLAG} \
	SRCCONF=${SRCCONF} \
	CROSS_TOOLCHAIN=mips-gcc \
	TARGET=mips \
	TARGET_ARCH=mips64 \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
