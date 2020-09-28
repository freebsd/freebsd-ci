#!/bin/sh

MAKECONF=${WORKSPACE}/`dirname $0`/make.conf

env \
	MAKECONF=${MAKECONF} \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=i386 \
	TARGET_ARCH=i386 \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
