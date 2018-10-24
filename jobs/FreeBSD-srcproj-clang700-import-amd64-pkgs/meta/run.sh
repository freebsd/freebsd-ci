#!/bin/sh

METADIR=/meta

# config network
cp ${METADIR}/resolv.conf /etc/
ifconfig vtnet0 inet6 `cat ${METADIR}/ip`
route -6 add default fe80::1%vtnet0

zpool create tank /dev/ada2
zfs set atime=off tank
zfs set compression=lz4 tank
zfs create tank/ports

svnlite co -q svn://svn.freebsd.org/ports/head /tank/ports

mkdir -p /usr/ports
mount_nullfs /tank/ports /usr/ports

cd /usr/ports
svnlite info
cd ports-mgmt/poudriere
make -DBATCH install clean

echo "ZPOOL=tank" >> /usr/local/etc/poudriere.conf
echo "export HTTP_PROXY=`cat ${METADIR}/http_proxy`" >> /usr/local/etc/poudriere.conf

SVN_REVISION=`cat /svn_revision.txt`
poudriere jail -c -j jail -m url=http://artifact.ci-dev.freebsd.org/snapshot/openssl111/r${SVN_REVISION}/amd64/amd64 -v `uname -r`
poudriere ports -c -f none -m null -M /tank/ports

poudriere bulk -t -j jail devel/gdb devel/kyua lang/perl5.26 lang/python net/scapy security/nist-kat security/nmap shells/ksh93 sysutils/coreutils

PKGS_TAR=/dev/ada3
tar cvf ${PKGS_TAR} -C /usr/local/poudriere/data/packages/jail-default/.latest .
