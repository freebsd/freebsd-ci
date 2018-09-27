#!/bin/sh

export JFLAG=${BUILDER_JFLAG}
export SRCCONF=${WORKSPACE}/`dirname $0`/src.conf
export TARGET=arm64
export TARGET_ARCH=aarch64

sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
