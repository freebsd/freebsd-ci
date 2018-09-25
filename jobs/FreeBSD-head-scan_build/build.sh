#!/bin/sh

SRCCONF=${WORKSPACE}/`dirname $0`/src.conf
MAKECONF=${WORKSPACE}/`dirname $0`/make.conf

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

true
