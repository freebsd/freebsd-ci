#!/bin/sh

SRCCONF=/workspace/`dirname $0`/src.conf

WORKSPACE=/workspace

env \
	JFLAG=${BUILDER_JFLAG} \
	SRCCONF=${SRCCONF} \
	TARGET=amd64 \
	TARGET_ARCH=amd64 \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel.sh
