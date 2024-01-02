#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=i386 \
	TARGET_ARCH=i386 \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
