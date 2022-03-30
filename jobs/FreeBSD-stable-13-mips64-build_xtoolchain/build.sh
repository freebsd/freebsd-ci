#!/bin/sh

JOBDIR=${WORKSPACE}/`dirname $0`

env \
	JFLAG=${BUILDER_JFLAG} \
	CROSS_TOOLCHAIN=mips64-gcc \
	TARGET=mips \
	TARGET_ARCH=mips64 \
	MAKECONF=${JOBDIR}/make.conf \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
