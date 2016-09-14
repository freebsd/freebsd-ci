#!/bin/sh

WORKSPACE=/workspace

export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
rm -fr ${MAKEOBJDIRPREFIX}

cd src

for d in bin sbin usr.bin usr.sbin lib libexec sys; do
	cd ${d};
	make -i -j ${BUILDER_JFLAG} CLANG_ANALYZE_OUTPUT_DIR=${WORKSPACE}/clangScanBuildReports CLANG_ANALYZE_OUTPUT=html analyze
	cd -
done
