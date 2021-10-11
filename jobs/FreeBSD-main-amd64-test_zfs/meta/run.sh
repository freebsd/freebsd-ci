#!/bin/sh

METADIR=/meta

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH

cat <<EOF >> /etc/kyua/kyua.conf
test_suites.FreeBSD.disks = '/dev/vtbd2 /dev/vtbd3 /dev/vtbd4 /dev/vtbd5 /dev/vtbd6'
EOF

newfs /dev/vtbd7
mount /dev/vtbd7 /tmp

# Enable services needed by tests
sysrc zfsd_enable="YES"
service zfsd start

cd /usr/tests/sys/cddl/zfs
set +e
/usr/bin/kyua test
rc=$?
if [ ${rc} -ne 0 ] && [ ${rc} -ne 1 ]; then
	exit ${rc}
fi

umount /tmp
set -e

/usr/bin/kyua report --verbose --results-filter passed,skipped,xfail,broken,failed --output test-report.txt
/usr/bin/kyua report-junit --output=test-report.xml
mv test-report.* ${METADIR}
