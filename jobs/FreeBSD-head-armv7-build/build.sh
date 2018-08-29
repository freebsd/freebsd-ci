#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=arm \
	TARGET_ARCH=armv7 \
	SRCCONF=${WORKSPACE}/`dirname $0`/src.conf \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
