#!/bin/sh

env \
	TARGET=amd64 \
	TARGET_ARCH=amd64 \
	USE_TEST_SUBR="disable-dtrace-tests.sh disable-zfs-tests.sh run-kyua.sh" \
	sh -x freebsd-ci/scripts/test/run-tests.sh
