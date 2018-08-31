#!/bin/sh

export TARGET=amd64
export TARGET_ARCH=amd64

sh -x freebsd-ci/scripts/test/run-tests.sh
