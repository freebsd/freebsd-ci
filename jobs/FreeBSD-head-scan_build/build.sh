#!/bin/sh

env SCAN_BUILD=scan-build36 ./freebsd-ci/scan-build/scan-world
