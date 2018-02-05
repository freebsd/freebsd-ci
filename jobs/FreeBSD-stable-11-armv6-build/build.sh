#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=arm \
	TARGET_ARCH=armv6 \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel.sh
