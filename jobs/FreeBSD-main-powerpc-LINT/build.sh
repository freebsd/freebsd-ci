#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=powerpc \
	TARGET_ARCH=powerpc \
	sh -ex freebsd-ci/scripts/build/build-kernel-LINT-head.sh
