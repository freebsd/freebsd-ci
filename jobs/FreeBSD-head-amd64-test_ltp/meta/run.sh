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

# runltp creates nobody, bin, and daemon users, but not root
echo 'root:x:0:0:root::' > /etc/passwd

# Workaround for https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=242955
kldload ext2fs

# Disable tests that hang undefinitely.
cat > /compat/linux/ltp-skipfile.conf << END
rt_sigtimedwait01 rt_sigtimedwait01
sigtimedwait01 sigtimedwait01
sigwaitinfo01 sigwaitinfo01
inotify06 inotify06
pidns05 pidns05
utstest_unshare_3 utstest_unshare_3
utstest_unshare_4 utstest_unshare_4
kill10 kill10
END

mdconfig -s 262144k

set +e
yes | limits -n 1024 chroot /compat/linux /opt/ltp/runltp -Q -S /ltp-skipfile.conf -b /dev/md0 -pl /ltp-results.log
echo $? > ${METADIR}/runltp.error
set -e

mv -v /compat/linux/ltp-results.log ${METADIR}
