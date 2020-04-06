#!/bin/sh

echo
echo "--------------------------------------------------------------"
echo "start kyua tests!"
echo "--------------------------------------------------------------"

cd /usr/tests
set +e
kyua test
rc=$?
set -e
if [ ${rc} -ne 0 ] && [ ${rc} -ne 1 ]; then
	exit ${rc}
fi
kyua report --verbose --results-filter passed,skipped,xfail,broken,failed --output test-report.txt
kyua report-junit --output=test-report.xml
mv test-report.* /meta
