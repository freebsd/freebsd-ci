#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=powerpc \
	TARGET_ARCH=powerpc \
	sh -x freebsd-ci/scripts/build/build-kernel-LINT.sh
