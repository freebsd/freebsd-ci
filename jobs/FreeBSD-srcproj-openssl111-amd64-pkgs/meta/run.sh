#!/bin/sh

METADIR=/meta

# config network
# XXX: need to be parameterized
echo "nameserver 1.1.1.1" > /etc/resolv.conf
ifconfig vtnet0 8.8.178.219/27
route add default 8.8.178.193

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

echo "ZPOOL=tank" > /usr/local/etc/poudriere.conf

SVN_REVISION=`cat /svn_revision.txt`
poudriere jail -c -j jail -m url=http://artifact.ci-dev.freebsd.org/snapshot/openssl111/${SVN_REVISION}/amd64/amd64/ -v `uname -r`
poudriere ports -c -f none -m null -M /tank/ports

poudriere bulk -t -j jail devel/gdb devel/kyua lang/perl5.26 lang/python net/scapy security/nist-kat security/nmap shells/ksh93 sysutils/coreutils

PKGS_TAR=/dev/ada3
tar cvf ${PKGS_TAR} -C /usr/local/poudriere/data/packages/jail-default .
