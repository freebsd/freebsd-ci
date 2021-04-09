#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=powerpc \
	TARGET_ARCH=powerpc \
	sh -ex ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel.sh
