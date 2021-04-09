#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=i386 \
	TARGET_ARCH=i386 \
	sh -ex freebsd-ci/scripts/build/build-kernel-LINT-head.sh
