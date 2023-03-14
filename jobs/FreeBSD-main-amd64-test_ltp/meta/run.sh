#!/bin/sh

METADIR=/meta

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH

# Enable services needed by tests
sysrc linux_enable="YES"
for i in proc sys tmp dev; do
	mkdir -p /compat/linux/$i
done
service linux start

# runltp creates nobody, bin, and daemon users, but not root
echo 'root:x:0:0:root::' > /compat/linux/etc/passwd

# runltp creates nobody, bin, daemon, sys, and users groups, but not root
echo 'root:x:0:' > /compat/linux/etc/group

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
mmap_11-2 mmap_11-2
mmap_24-1 mmap_24-1
sigaction_16-1 sigaction_16-1
END

# Add Open POSIX to the default run.
echo "openposix" >> /compat/linux/opt/ltp/scenario_groups/default

mdconfig -s 512m

set +e
yes | chroot /compat/linux /opt/ltp/runltp -Q -S /ltp-skipfile.conf -b /dev/md0 -pl /ltp-results.log
echo $? > ${METADIR}/runltp.error
set -e

mv -v /compat/linux/ltp-results.log ${METADIR}
