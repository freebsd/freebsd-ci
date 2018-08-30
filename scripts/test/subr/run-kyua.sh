#!/bin/sh

echo
echo "--------------------------------------------------------------"
echo "start kyua tests!"
echo "--------------------------------------------------------------"

cd /usr/tests
/usr/local/bin/kyua test                                                       
/usr/local/bin/kyua report --verbose --results-filter passed,skipped,xfail,broken,failed --output test-report.txt
/usr/local/bin/kyua report-junit --output=test-report.xml                      
mv test-report.* /tmp/meta
