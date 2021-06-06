#!/bin/sh

export JFLAG=${BUILDER_JFLAG}
export TARGET=i386
export TARGET_ARCH=i386
export WITH_LIB32=0
export WITH_DEBUG=1
export WITH_DOC=1
export WITH_TESTS=1

sh -ex freebsd-ci/scripts/build/build-images.sh
