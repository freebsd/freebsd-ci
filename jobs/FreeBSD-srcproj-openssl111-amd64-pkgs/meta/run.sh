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
