#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=powerpc \
	TARGET_ARCH=powerpc64 \
	KERNCONF=LINT64 \
	sh -x freebsd-ci/scripts/build/build-kernel-LINT-head.sh
