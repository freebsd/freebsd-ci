#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=amd64 \
	TARGET_ARCH=amd64 \
	sh -ex ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
