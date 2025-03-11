#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=amd64 \
	TARGET_ARCH=amd64 \
	SRCCONF=${WORKSPACE}/`dirname $0`/src.conf \
	MAKECONF_AMD=${WORKSPACE}/`dirname $0`/make-amd.conf \
	MAKECONF_INTEL=${WORKSPACE}/`dirname $0`/make-intel.conf \
	TESTTYPE=arch \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-reproducible.sh
