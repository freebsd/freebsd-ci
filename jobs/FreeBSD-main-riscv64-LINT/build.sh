#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=riscv \
	TARGET_ARCH=riscv64 \
	sh -x freebsd-ci/scripts/build/build-kernel-LINT-head.sh
