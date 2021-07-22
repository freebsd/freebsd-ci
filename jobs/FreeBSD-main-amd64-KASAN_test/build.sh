#!/bin/sh

export TARGET=amd64
export TARGET_ARCH=amd64

export KERNCONF=GENERIC-KASAN

export USE_TEST_SUBR="
disable-dtrace-tests.sh
disable-zfs-tests.sh
disable-notyet-tests.sh
run-kyua.sh
"

sh -x freebsd-ci/scripts/test/run-tests.sh
