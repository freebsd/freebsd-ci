#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=arm64 \
	sh -x freebsd-ci/scripts/build/build-world-kernel.sh
