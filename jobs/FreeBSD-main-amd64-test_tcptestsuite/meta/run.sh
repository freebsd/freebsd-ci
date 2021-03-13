#!/bin/sh

METADIR=/meta

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH

cat <<EOF >> /etc/kyua/kyua.conf
test_suites.FreeBSD.disks = '/dev/ada2 /dev/ada3 /dev/ada4 /dev/ada5 /dev/ada6'
EOF

newfs /dev/ada7
mount /dev/ada7 /tmp

# Required by Packet Drill
sysctl vm.old_mlock=1

cd /usr/local/tests/
set +e
/usr/bin/kyua test_suites.FreeBSD.allow_sysctl_side_effects=1
rc=$?
if [ ${rc} -ne 0 ] && [ ${rc} -ne 1 ]; then
	exit ${rc}
fi

umount /tmp
set -e

/usr/bin/kyua report --verbose --results-filter passed,skipped,xfail,broken,failed --output test-report.txt
/usr/bin/kyua report-junit --output=test-report.xml
mv test-report.* ${METADIR}
