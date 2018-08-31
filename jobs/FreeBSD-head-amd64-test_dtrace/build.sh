#!/bin/sh

export TARGET=amd64
export TARGET_ARCH=amd64

export USE_TEST_SUBR="
disable-zfs-tests.sh
"

sh -x freebsd-ci/scripts/test/run-tests.sh
