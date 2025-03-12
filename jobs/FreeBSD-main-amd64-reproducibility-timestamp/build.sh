#!/bin/sh

set -ex

export TESTTYPE=timestamp
. ${WORKSPACE}/freebsd-ci/scripts/build/build-reproducible-pre.sh
export TARGET=amd64
export TARGET_ARCH=amd64

echo $SOURCE_DATE_EPOCH
echo $SOURCE_DATE_EPOCH_BASE
cd /usr/src
build_world_kernel
export MAKEOBJDIRPREFIX=${WORKSPACE}/objtest
rm -fr ${MAKEOBJDIRPREFIX}
# One year from today's date at 00:00:00 UTC
export SOURCE_DATE_EPOCH=$(date -u -j -v+1y -f "%Y-%m-%d %H:%M:%S" "$(date -u +%Y-%m-%d) 00:00:00" +%s)
echo $SOURCE_DATE_EPOCH
build_world_kernel

. ${WORKSPACE}/freebsd-ci/scripts/build/build-reproducible.sh
