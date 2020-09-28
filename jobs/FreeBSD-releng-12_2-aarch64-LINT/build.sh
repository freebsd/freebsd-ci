#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=arm64 \
	TARGET_ARCH=aarch64 \
	sh -x freebsd-ci/scripts/build/build-kernel-LINT.sh
