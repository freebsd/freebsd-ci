#!/bin/sh

set -ex

export TESTTYPE=path
. ${WORKSPACE}/freebsd-ci/scripts/build/build-reproducible-pre.sh
export TARGET=amd64
export TARGET_ARCH=amd64

echo $SOURCE_DATE_EPOCH
echo $SOURCE_DATE_EPOCH_BASE
cp -Rp /usr/src ${WORKSPACE}/src1
cp -Rp /usr/src ${WORKSPACE}/src2
cd ${WORKSPACE}/src1
build_world_kernel
export MAKEOBJDIRPREFIX=${WORKSPACE}/objtest
rm -fr ${MAKEOBJDIRPREFIX}
cd ${WORKSPACE}/src2
build_world_kernel

. ${WORKSPACE}/freebsd-ci/scripts/build/build-reproducible.sh
