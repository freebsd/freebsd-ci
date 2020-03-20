#!/bin/sh

JOB_BASE=${WORKSPACE}/`dirname $0`
SRCCONF=${JOB_BASE}/src.conf
MAKECONF=${JOB_BASE}make.conf

export MAKEOBJDIRPREFIX=/tmp/obj
rm -fr ${MAKEOBJDIRPREFIX}

CLANG_ANALYZE_OUTPUT_DIR=${WORKSPACE}/clangScanBuildReports
rm -fr ${CLANG_ANALYZE_OUTPUT_DIR}

cd ${WORKSPACE}/src

set -e
for d in bin sbin usr.bin usr.sbin lib libexec sys; do
	cd ${d};
	make -i -j ${BUILDER_JFLAG} \
		CLANG_ANALYZE_OUTPUT_DIR=${CLANG_ANALYZE_OUTPUT_DIR} \
		CLANG_ANALYZE_OUTPUT=html  \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF} \
		analyze
	cd -
done

cd ${WORKSPACE}
sh ${JOB_BASE}/backtrace-submit.sh ${CLANG_ANALYZE_OUTPUT_DIR}

true
