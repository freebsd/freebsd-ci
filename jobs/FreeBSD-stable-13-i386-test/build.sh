#!/bin/sh

export TARGET=i386
export TARGET_ARCH=i386

export USE_TEST_SUBR="
disable-dtrace-tests.sh
disable-zfs-tests.sh
disable-notyet-tests.sh
run-kyua.sh
"

sh -ex freebsd-ci/scripts/test/run-tests.sh
