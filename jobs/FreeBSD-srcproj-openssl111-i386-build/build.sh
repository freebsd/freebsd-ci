#!/bin/sh

export JFLAG=${BUILDER_JFLAG}
export MAKECONF=${WORKSPACE}/`dirname $0`/make.conf
export SRCCONF=${WORKSPACE}/`dirname $0`/src.conf
export TARGET=i386
export TARGET_ARCH=i386

sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh
