#!/bin/sh

SRCCONF=${WORKSPACE}/`dirname $0`/src.conf

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=mips \
	TARGET_ARCH=mipsn32 \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
