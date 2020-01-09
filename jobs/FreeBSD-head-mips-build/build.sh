#!/bin/sh

SRCCONF=${WORKSPACE}/`dirname $0`/src.conf

env \
	JFLAG=${BUILDER_JFLAG} \
	SRCCONF=${SRCCONF} \
	TARGET=mips \
	TARGET_ARCH=mips \
	CROSS_TOOLCHAIN=mips-gcc6 \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
