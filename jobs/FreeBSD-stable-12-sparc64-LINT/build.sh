#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=sparc64 \
	TARGET_ARCH=sparc64 \
	sh -ex freebsd-ci/scripts/build/build-kernel-LINT.sh
