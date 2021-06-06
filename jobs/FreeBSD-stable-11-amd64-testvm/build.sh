#!/bin/sh

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=amd64 \
	TARGET_ARCH=amd64 \
	WITH_LIB32=1 \
	WITH_DEBUG=1 \
	WITH_DOC=1 \
	WITH_TESTS=1 \
	sh -ex freebsd-ci/scripts/build/build-test_image-11.sh
