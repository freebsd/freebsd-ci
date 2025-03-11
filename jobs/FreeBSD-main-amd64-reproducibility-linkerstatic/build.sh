#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=amd64 \
	TARGET_ARCH=amd64 \
	SRCCONF=${WORKSPACE}/`dirname $0`/src.conf \
	TESTTYPE=linkerstatic \
	MAKECONF_STATIC=${WORKSPACE}/`dirname $0`/make-static.conf \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-reproducible.sh
