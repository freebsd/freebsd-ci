#!/bin/sh

set -ex

export TESTTYPE=locale
. ${WORKSPACE}/freebsd-ci/scripts/build/build-reproducible-pre.sh
export TARGET=amd64
export TARGET_ARCH=amd64

echo $SOURCE_DATE_EPOCH
echo $SOURCE_DATE_EPOCH_BASE
cd /usr/src
build_world_kernel
export MAKEOBJDIRPREFIX=${WORKSPACE}/objtest
rm -fr ${MAKEOBJDIRPREFIX}
export LC_ALL=fr_FR.UTF-8
build_world_kernel

. ${WORKSPACE}/freebsd-ci/scripts/build/build-reproducible.sh
