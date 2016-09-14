#!/bin/sh

cd src

set +e
for d in bin sbin usr.bin usr.sbin lib libexec sys; do
	cd ${d};
	make -j ${BUILDER_JFLAG} CLANG_ANALYZE_OUTPUT_DIR=${WORKSPACE}/clangScanBuildReports CLANG_ANALYZE_OUTPUT=html analyze
	cd -
done
