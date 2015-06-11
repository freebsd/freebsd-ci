#!/bin/sh

export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"

JNAME="${JOB_NAME}"

ZFS_PARENT=zroot/j/jails

JHOME=/j/jails
JPATH=${JHOME}/${JNAME}

echo "clean jail ${JNAME}"

sudo jail -r ${JNAME} || true
sudo ifconfig ${BUILDER_NETIF} inet6 ${BUILDER_JAIL_IP} -alias || true

sudo umount ${JPATH}/workspace || true
sudo umount ${JPATH}/dev || true

sudo zfs destroy ${ZFS_PARENT}/${JNAME} || true
