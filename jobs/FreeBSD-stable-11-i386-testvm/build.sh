#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=i386 \
	TARGET_ARCH=i386 \
	WITH_LIB32=0 \
	WITH_DEBUG=1 \
	WITH_DOC=1 \
	WITH_TESTS=1 \
	sh -ex freebsd-ci/scripts/build/build-test_image-11.sh
