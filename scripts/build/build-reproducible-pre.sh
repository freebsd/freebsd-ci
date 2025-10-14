if [ -f "${WORKSPACE}/$(dirname "$0")/src.conf" ]; then
	export SRCCONF="${WORKSPACE}/$(dirname "$0")/src.conf"
else
	export SRCCONF="/dev/null"
fi
if [ -f "${WORKSPACE}/$(dirname "$0")/make.conf" ]; then
	export MAKECONF="${WORKSPACE}/$(dirname "$0")/make.conf"
else
	export MAKECONF="/dev/null"
fi
export JFLAG=${BUILDER_JFLAG}
export ARTIFACT=${WORKSPACE}/diff.html
export ARTIFACT_DEST=artifact/reproducibility/${FBSD_BRANCH}/${TARGET}/${TARGET_ARCH}/${GIT_COMMIT}-${TESTTYPE}.html
# Set SOURCE_DATE_EPOCH to today at 00:00:00 UTC
export SOURCE_DATE_EPOCH=$(date -u -j -f "%Y-%m-%d %H:%M:%S" "$(date -u +%Y-%m-%d) 00:00:00" +%s)
export SOURCE_DATE_EPOCH_BASE=${SOURCE_DATE_EPOCH}
if [ -n "${CROSS_TOOLCHAIN}" ]; then
	CROSS_TOOLCHAIN_PARAM=CROSS_TOOLCHAIN=${CROSS_TOOLCHAIN}
	export CROSS_TOOLCHAIN_PARAM
fi
export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
rm -fr ${MAKEOBJDIRPREFIX}

build_world_kernel() {
make -j ${JFLAG} \
	buildworld \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	${CROSS_TOOLCHAIN_PARAM} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}
make -j ${JFLAG} \
	buildkernel \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	${CROSS_TOOLCHAIN_PARAM} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}
}
