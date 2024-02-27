#!/bin/sh

JOBDIR=${WORKSPACE}/`dirname $0`

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=powerpc \
	TARGET_ARCH=powerpc \
	MAKECONF=${JOBDIR}/make.conf \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
