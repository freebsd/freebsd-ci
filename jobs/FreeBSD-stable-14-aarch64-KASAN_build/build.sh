#!/bin/sh

JOBDIR=${WORKSPACE}/`dirname $0`

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=arm64 \
	TARGET_ARCH=aarch64 \
	MAKECONF=${JOBDIR}/make.conf \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-kernel-head.sh
