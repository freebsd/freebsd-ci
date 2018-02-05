#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=arm \
	TARGET_ARCH=armv6 \
	SRCCONF=${WORKSPACE}/`dirname $0`/src.conf \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel.sh
