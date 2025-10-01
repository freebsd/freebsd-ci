#!/bin/sh

JOBDIR=${WORKSPACE}/`dirname $0`

env \
	JFLAG=${BUILDER_JFLAG} \
	SRCCONF=${JOBDIR}/src.conf \
	MAKECONF=${JOBDIR}/make.conf \
	TARGET=amd64 \
	TARGET_ARCH=amd64 \
	KERNCONF=GENERIC \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
