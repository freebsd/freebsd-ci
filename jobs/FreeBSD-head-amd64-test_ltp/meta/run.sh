#!/bin/sh

METADIR=/meta

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH

# Enable services needed by tests
sysrc linux_enable="YES"
for i in proc sys tmp; do
	mkdir -p /compat/linux/$i
done
service linux start

# Disable tests that hang undefinitely.
cat > /compat/linux/ltp-skipfile.conf << END
rt_sigtimedwait01 rt_sigtimedwait01
sigtimedwait01 sigtimedwait01
sigwaitinfo01 sigwaitinfo01
inotify06 inotify06
pidns05 pidns05
utstest_unshare_3 utstest_unshare_3
utstest_unshare_4 utstest_unshare_4
fork09 fork09
END

yes | chroot /compat/linux /opt/ltp/runltp -Q -S /ltp-skipfile.conf -pl /ltp-results.log

echo $? > ${METADIR}/runltp.error
mv -v /compat/linux/ltp-results.log ${METADIR}
