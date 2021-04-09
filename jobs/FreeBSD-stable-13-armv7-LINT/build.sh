#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=arm \
	TARGET_ARCH=armv7 \
	sh -ex freebsd-ci/scripts/build/build-kernel-LINT-head.sh
