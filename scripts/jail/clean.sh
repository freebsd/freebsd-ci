#!/bin/sh

export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"

JNAME="${JOB_NAME}"

ZFS_PARENT=zroot/j/jails

JHOME=/j/jails
JPATH=${JHOME}/${JNAME}

echo "clean jail ${JNAME}"

sudo jail -r ${JNAME} || true

if [ ${BUILDER_NETIF} -a ${BUILDER_JAIL_IP6} ]; then
	sudo ifconfig ${BUILDER_NETIF} inet6 ${BUILDER_JAIL_IP6} -alias || true
fi
if [ ${BUILDER_NETIF} -a ${BUILDER_JAIL_IP4} ]; then
	sudo ifconfig ${BUILDER_NETIF} inet ${BUILDER_JAIL_IP4} -alias || true
fi

sudo umount ${JPATH}/workspace || true
sudo umount ${JPATH}/dev || true

sudo zfs destroy ${ZFS_PARENT}/${JNAME} || true
