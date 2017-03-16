#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=amd64 \
	TARGET_ARCH=amd64 \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel.sh
