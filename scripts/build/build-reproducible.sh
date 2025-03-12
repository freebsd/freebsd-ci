#!/bin/sh

set -ex

if [ -n "${CROSS_TOOLCHAIN}" ]; then
	CROSS_TOOLCHAIN_PARAM=CROSS_TOOLCHAIN=${CROSS_TOOLCHAIN}
fi

MAKECONF=${MAKECONF:-/dev/null}
SRCCONF=${SRCCONF:-/dev/null}
FBSD_BRANCH=${FBSD_BRANCH:-main}
JFLAG=${JFLAG:-12}
TARGET=${TARGET:-amd64}
TARGET_ARCH=${TARGET_ARCH:-amd64}
ARTIFACT=${WORKSPACE}/diff.html
ARTIFACT_DEST=artifact/reproducibility/${FBSD_BRANCH}/${TARGET}/${TARGET_ARCH}/${GIT_COMMIT}-${TESTTYPE}.html
export TESTTYPE=${TESTTYPE:-timestamp}
# Set SOURCE_DATE_EPOCH to today at 00:00:00 UTC
export SOURCE_DATE_EPOCH=$(date -u -j -f "%Y-%m-%d %H:%M:%S" "$(date -u +%Y-%m-%d) 00:00:00" +%s)

if [ ${TESTTYPE} = "timestamp" ]; then
	echo $SOURCE_DATE_EPOCH
	export MAKEOBJDIRPREFIX=${WORKSPACE}/obj1
	rm -fr ${MAKEOBJDIRPREFIX}
	cd /usr/src
	sudo -E make -j ${JFLAG} -DNO_CLEAN \
		buildworld \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	sudo -E make -j ${JFLAG} -DNO_CLEAN \
		buildkernel \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	# One year from today's date at 00:00:00 UTC
	export SOURCE_DATE_EPOCH=$(date -u -j -v+1y -f "%Y-%m-%d %H:%M:%S" "$(date -u +%Y-%m-%d) 00:00:00" +%s)
	echo $SOURCE_DATE_EPOCH
	export MAKEOBJDIRPREFIX=${WORKSPACE}/obj2
	rm -fr ${MAKEOBJDIRPREFIX}
	sudo -E make -j ${JFLAG} -DNO_CLEAN \
		buildworld \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	sudo -E make -j ${JFLAG} -DNO_CLEAN \
		buildkernel \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	diffoscope --html ${WORKSPACE}/diff.html ${WORKSPACE}/obj1 ${WORKSPACE}/obj2
elif [ ${TESTTYPE} = "uid" ]; then
	echo $SOURCE_DATE_EPOCH
	export MAKEOBJDIRPREFIX=${WORKSPACE}/objroot
	rm -fr ${MAKEOBJDIRPREFIX}
	cd /usr/src
	export LC_ALL=C
	sudo -E make -j ${JFLAG} -DNO_CLEAN -DNO_ROOT \
		buildworld \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	sudo -E make -j ${JFLAG} -DNO_CLEAN -DNO_ROOT \
		buildkernel \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	export MAKEOBJDIRPREFIX=${WORKSPACE}/objnobody
	rm -fr ${MAKEOBJDIRPREFIX}
	sudo -u nobody -E make -j ${JFLAG} -DNO_CLEAN -DNO_ROOT \
		buildworld \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	sudo -u nobody -E make -j ${JFLAG} -DNO_CLEAN -DNO_ROOOT \
		buildkernel \
		TARGET=${TARGET} \
		TARGET_ARCH=${TARGET_ARCH} \
		${CROSS_TOOLCHAIN_PARAM} \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF}
	diffoscope --html ${WORKSPACE}/diff.html ${WORKSPACE}/objroot ${WORKSPACE}/objnobody
fi

diffoscope --html ${WORKSPACE}/diff.html ${WORKSPACE}/obj ${WORKSPACE}/objtest
if [ -f "${WORKSPACE}/diff.html" ]; then
	sudo mkdir -p ${ARTIFACT_DEST}
	mv ${ARTIFACT} ${ARTIFACT_DEST}
	exit 1
else
	exit 0
fi
