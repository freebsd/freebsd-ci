#!/bin/sh

SRCCONF=/workspace/`dirname $0`/src.conf
MAKECONF=/workspace/`dirname $0`/make.conf

sudo cp ${SRCCONF} /etc
sudo cp ${MAKECONF} /etc
env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=amd64 \
	TARGET_ARCH=amd64 \
	SRCCONF=${SRCCONF} \
	MAKECONF=${MAKECONF} \
	sh -x freebsd-ci/scripts/build/build-world-kernel.sh
