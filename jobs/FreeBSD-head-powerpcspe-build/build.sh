#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=powerpc \
	TARGET_ARCH=powerpcspe \
	sh -x freebsd-ci/scripts/build/build-world-kernel.sh
