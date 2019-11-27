#!/bin/sh

METADIR=/meta

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH

# Enable services needed by tests
sysrc linux_enable="YES"
service linux start

chroot /compat/linux /opt/ltp/runltp -Q

# XXX: Missing report generation
echo $? > test-report.xml

mv test-report.* ${METADIR}
