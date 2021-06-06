#!/bin/sh

SRCCONF=${WORKSPACE}/`dirname $0`/src.conf

env \
	JFLAG=${BUILDER_JFLAG} \
	SRCCONF=${SRCCONF} \
	CROSS_TOOLCHAIN=mips-gcc \
	TARGET=mips \
	TARGET_ARCH=mips \
	sh -ex ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
