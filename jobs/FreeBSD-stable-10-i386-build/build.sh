#!/bin/sh

SRCCONF=${WORKSPACE}/`dirname $0`/src.conf

env \
	JFLAG=${BUILDER_JFLAG} \
	SRCCONF=${SRCCONF} \
	TARGET=i386 \
	TARGET_ARCH=i386 \
	sh -x freebsd-ci/scripts/build/build-world-kernel.sh
