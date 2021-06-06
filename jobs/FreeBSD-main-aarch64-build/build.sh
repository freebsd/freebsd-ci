#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=arm64 \
	TARGET_ARCH=aarch64 \
	SRCCONF=${WORKSPACE}/`dirname $0`/src.conf \
	sh -ex ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
