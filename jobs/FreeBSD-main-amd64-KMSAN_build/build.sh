#!/bin/sh

JOBDIR=${WORKSPACE}/`dirname $0`

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=amd64 \
	TARGET_ARCH=amd64 \
	MAKECONF=${JOBDIR}/make.conf \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-kernel-head.sh
