#!/bin/sh

export JFLAG=${BUILDER_JFLAG}
export TARGET=amd64
export TARGET_ARCH=amd64

sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
