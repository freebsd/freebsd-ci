#!/bin/sh

METADIR=/tmp/meta

cat <<EOF >> /usr/local/etc/kyua/kyua.conf
test_suites.FreeBSD.disks = '/dev/ada1 /dev/ada2 /dev/ada3 /dev/ada4 /dev/ada5'
EOF

cd /usr/tests/sys/cddl/zfs
set +e
/usr/local/bin/kyua test
rc=$?
set -e
if [ ${rc} -ne 0 ] && [ ${rc} -ne 1 ]; then
	exit ${rc}
fi

/usr/local/bin/kyua report --verbose --results-filter passed,skipped,xfail,broken,failed --output test-report.txt
/usr/local/bin/kyua report-junit --output=test-report.xml
mv test-report.* ${METADIR}
