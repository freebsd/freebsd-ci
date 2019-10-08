#!/bin/sh

METADIR=/meta

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
PATH=${PATH}:/usr/tests/sys/cddl/zfs/bin
export PATH

cat <<EOF >> /usr/local/etc/kyua/kyua.conf
test_suites.FreeBSD.disks = '/dev/ada2 /dev/ada3 /dev/ada4 /dev/ada5 /dev/ada6'
EOF

newfs /dev/ada7
mount /dev/ada7 /tmp

# Enable services needed by tests
sysrc zfsd_enable="YES"
service zfsd start

cd /usr/tests/sys/cddl/zfs
set +e
/usr/local/bin/kyua test
rc=$?
if [ ${rc} -ne 0 ] && [ ${rc} -ne 1 ]; then
	exit ${rc}
fi

umount /tmp
set -e

/usr/local/bin/kyua report --verbose --results-filter passed,skipped,xfail,broken,failed --output test-report.txt
/usr/local/bin/kyua report-junit --output=test-report.xml
mv test-report.* ${METADIR}
