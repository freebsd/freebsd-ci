#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=riscv \
	TARGET_ARCH=riscv64 \
	sh -ex freebsd-ci/scripts/build/build-kernel-LINT-head.sh
