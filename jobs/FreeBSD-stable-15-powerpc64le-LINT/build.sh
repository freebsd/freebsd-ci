#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=powerpc \
	TARGET_ARCH=powerpc64le \
	KERNCONF=LINT64LE \
	sh -x freebsd-ci/scripts/build/build-kernel-LINT-head.sh
