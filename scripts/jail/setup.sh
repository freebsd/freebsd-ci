#!/bin/sh

export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"

JNAME="${JOB_NAME}"

ZFS_PARENT=zroot/j/jails

JHOME=/j/jails
JPATH=${JHOME}/${JNAME}

JOB_CONF=freebsd-ci/jobs/${JOB_NAME}/job.conf

TARGET=amd64
TARGET_ARCH=amd64
WITH_32BIT=1
OSRELEASE=10.3-RELEASE

echo "env:"
/usr/bin/env

if [ -f ${JOB_CONF} ]; then
	. ${JOB_CONF}
else
	echo "warning: job configuration file not found, use default settings."
fi

echo "setup jail ${JNAME} using following parameters:"
echo "TARGET=${TARGET}"
echo "TARGET_ARCH=${TARGET_ARCH}"
echo "WITH_32BIT=${WITH_32BIT}"
echo "OSRELEASE=${OSRELEASE}"

RELEASE_TYPE=`echo ${OSRELEASE} | cut -f 2 -d '-' | tr -d [:digit:]`
case ${RELEASE_TYPE} in
"RELEASE"|"BETA"|"RC")
	SUBDIR=releases
	;;
*)
	SUBDIR=snapshots
	;;
esac
BASE_URL=https://download.FreeBSD.org/ftp/${SUBDIR}/${TARGET}/${TARGET_ARCH}/${OSRELEASE}

fetch -m ${BASE_URL}/base.txz
if [ ${WITH_32BIT} -eq 1 ]; then
	fetch -m ${BASE_URL}/lib32.txz
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

eval BUILDER_IP6="\$BUILDER_${EXECUTOR_NUMBER}_IP6"
eval BUILDER_IP4="\$BUILDER_${EXECUTOR_NUMBER}_IP4"

printf "${BUILDER_RESOLV_CONF}" | sudo tee ${JPATH}/etc/resolv.conf

if [ ${BUILDER_NETIF} -a ${BUILDER_JAIL_IP6} ]; then
	sudo ifconfig ${BUILDER_NETIF} inet6 ${BUILDER_JAIL_IP6} alias
	JAIL_ARG_IP6="ip6.addr=${BUILDER_JAIL_IP6}"
else
	JAIL_ARG_IP6="ip6=disable"
fi
if [ ${BUILDER_NETIF} -a ${BUILDER_JAIL_IP4} ]; then
	sudo ifconfig ${BUILDER_NETIF} inet ${BUILDER_JAIL_IP4} alias
	JAIL_ARG_IP4="ip4.addr=${BUILDER_JAIL_IP4}"
else
	JAIL_ARG_IP4="ip4=disable"
fi

sudo jail -c persist \
	name="${JNAME}" \
	path="${JPATH}" \
	osrelease="${OSRELEASE}" \
	host.hostname="${JNAME}.jail.ci.FreeBSD.org" \
	${JAIL_ARG_IP6} \
	${JAIL_ARG_IP4} \
	allow.chflags

echo "setup build environment"

sudo jexec ${JNAME} sh -c "env ASSUME_ALWAYS_YES=yes pkg update"
if [ -s freebsd-ci/jobs/${JOB_NAME}/pkg-list ]; then
	sudo jexec ${JNAME} sh -c "pkg install -y `cat freebsd-ci/jobs/${JOB_NAME}/pkg-list`"
fi

# remove network for quarantine env
if [ "$QUARANTINE" ]; then
	if [ ${BUILDER_NETIF} -a ${BUILDER_JAIL_IP6} ]; then
		sudo ifconfig ${BUILDER_NETIF} inet6 ${BUILDER_JAIL_IP6} -alias
		sudo jail -m name=${JNAME} ip6=disable ip6.addr=
	fi
	if [ ${BUILDER_NETIF} -a ${BUILDER_JAIL_IP4} ]; then
		sudo ifconfig ${BUILDER_NETIF} inet ${BUILDER_JAIL_IP4} -alias
		sudo jail -m name=${JNAME} ip4=disable ip4.addr=
	fi
fi

echo "build environment:"

sudo jexec ${JNAME} sh -c "uname -a"
sudo jexec ${JNAME} sh -c "pkg info -q"
