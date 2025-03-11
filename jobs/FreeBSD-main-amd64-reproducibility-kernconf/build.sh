#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=amd64 \
	TARGET_ARCH=amd64 \
	SRCCONF=${WORKSPACE}/`dirname $0`/src.conf \
	TESTTYPE=kernconf \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-reproducible.sh
