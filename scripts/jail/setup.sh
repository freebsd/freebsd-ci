#!/bin/sh

export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"

JNAME="${JOB_NAME}"

ZFS_PARENT=zroot/j/jails

JHOME=/j/jails
JPATH=${JHOME}/${JNAME}

TARGET=amd64
TARGET_ARCH=amd64
WITH_32BIT=1
OSRELEASE=11.0-CURRENT

echo "env:"
/usr/bin/env

echo "setup jail ${JNAME}"

fetch -m http://ftp.freebsd.org:/pub/FreeBSD/snapshots/${TARGET}/${TARGET_ARCH}/${OSRELEASE}/base.txz
if [ ${WITH_32BIT} -eq 1 ]; then
	fetch -m http://ftp.freebsd.org:/pub/FreeBSD/snapshots/${TARGET}/${TARGET_ARCH}/${OSRELEASE}/lib32.txz
fi

sudo zfs create ${ZFS_PARENT}/${JNAME}

sudo tar Jxf base.txz -C ${JPATH}
if [ ${WITH_32BIT} -eq 1 ]; then
	sudo tar Jxf lib32.txz -C ${JPATH}
fi

if [ -x ${JPATH}/bin/freebsd-version ]; then
	OSRELEASE=`${JPATH}/bin/freebsd-version -u`
fi

sudo mount -t devfs devfs ${JPATH}/dev
sudo devfs -m ${JPATH}/dev rule -s 4 applyset

sudo mkdir ${JPATH}/workspace
sudo mount -t nullfs ${WORKSPACE} ${JPATH}/workspace

printf "${BUILDER_RESOLV_CONF}" | sudo tee ${JPATH}/etc/resolv.conf

sudo ifconfig ${BUILDER_NETIF} inet6 ${BUILDER_JAIL_IP} alias
sudo jail -c persist name="${JNAME}" path="${JPATH}" osrelease="${OSRELEASE}" host.hostname="${JNAME}.jail.ci.FreeBSD.org" ip6.addr="${BUILDER_JAIL_IP}" ip4=disable allow.chflags

echo "setup build environment"

sudo jexec ${JNAME} sh -c "env ASSUME_ALWAYS_YES=yes pkg update"
sudo jexec ${JNAME} sh -c "pkg install -y `cat freebsd-ci/jobs/${JOB_NAME}/pkg-list`"

echo "build environment:"

sudo jexec ${JNAME} sh -c "uname -a"
sudo jexec ${JNAME} sh -c "pkg info -q"
