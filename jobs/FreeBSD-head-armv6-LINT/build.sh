#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=arm \
	TARGET_ARCH=armv6 \
	sh -x freebsd-ci/scripts/build/build-kernel-LINT.sh
