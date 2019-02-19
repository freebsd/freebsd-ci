#!/bin/sh

METADIR=/meta

# config network
cp ${METADIR}/resolv.conf /etc/
ifconfig vtnet0 inet6 `cat ${METADIR}/ip`
route -6 add default fe80::1%vtnet0

SVN_REVISION=`cat /.svn_revision.txt`

zpool create tank /dev/ada2
zfs set atime=off tank
zfs set compression=lz4 tank
zfs create tank/src
zfs create tank/ports

svnlite co -q svn://svn.freebsd.org/base/head@${SVN_REVISION} /tank/src
svnlite co -q svn://svn.freebsd.org/ports/head /tank/ports

mkdir -p /usr/src
mkdir -p /usr/ports
mount_nullfs /tank/src /usr/src
mount_nullfs /tank/ports /usr/ports

cd /usr/ports
svnlite info
cd graphics/drm-current-kmod
export HTTP_PROXY=${BUILDER_HTTP_PROXY}
make -DBATCH package

RESULT=$?
echo ${RESULT} > ${METADIR}/result
