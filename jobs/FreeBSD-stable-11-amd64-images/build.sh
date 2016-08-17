#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=amd64 \
	TARGET_ARCH=amd64 \
	WITH_LIB32=1 \
	WITH_DEBUG=1 \
	sh -x freebsd-ci/scripts/build/build-images.sh
