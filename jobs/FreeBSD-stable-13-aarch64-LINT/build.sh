#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=arm64 \
	TARGET_ARCH=aarch64 \
	sh -ex freebsd-ci/scripts/build/build-kernel-LINT-head.sh
