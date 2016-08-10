#!/bin/sh

WORKSAPCE=/workspace

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=amd64 \
	TARGET_ARCH=amd64 \
	sh -x ${WORKSAPCE}/freebsd-ci/scripts/build/build-world-kernel.sh
