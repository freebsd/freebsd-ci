#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=mips \
	TARGET_ARCH=mips \
	SRCCONF=${WORKSPACE}/`dirname $0`/src.conf \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
