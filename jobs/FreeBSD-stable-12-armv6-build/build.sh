#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=arm \
	TARGET_ARCH=armv6 \
	sh -ex ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
