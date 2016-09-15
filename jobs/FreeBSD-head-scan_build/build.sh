#!/bin/sh

SRCCONF=/workspace/`dirname $0`/src.conf
MAKECONF=/workspace/`dirname $0`/make.conf

WORKSPACE=/workspace

export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
rm -fr ${MAKEOBJDIRPREFIX}

CLANG_ANALYZE_OUTPUT_DIR=${WORKSPACE}/clangScanBuildReports
rm -fr ${CLANG_ANALYZE_OUTPUT_DIR}

mkdir -p ${JOB_NAME}
ln -sf ../src ${JOB_NAME}/src
cd ${JOB_NAME}/src

set -e
#for d in bin sbin usr.bin usr.sbin lib libexec sys; do
for d in bin; do
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
