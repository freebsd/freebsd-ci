#!/bin/sh

SRCCONF=/workspace/`dirname $0`/src.conf
MAKECONF=/workspace/`dirname $0`/make.conf

WORKSPACE=/workspace

export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
rm -fr ${MAKEOBJDIRPREFIX}

cd src

for d in bin sbin usr.bin usr.sbin lib libexec sys; do
	cd ${d};
	make -i -j ${BUILDER_JFLAG} \
		CLANG_ANALYZE_OUTPUT_DIR=${WORKSPACE}/clangScanBuildReports \
		CLANG_ANALYZE_OUTPUT=html  \
		__MAKE_CONF=${MAKECONF} \
		SRCCONF=${SRCCONF} \
		analyze
	cd -
done
