#!/bin/sh

. freebsd-ci/scripts/jail/jail.conf

eval BUILDER_JAIL_IP6="\$BUILDER_${EXECUTOR_NUMBER}_IP6"
eval BUILDER_JAIL_IP4="\$BUILDER_${EXECUTOR_NUMBER}_IP4"

if [ -f "${JAIL_CONF}" ]; then
	. ${JAIL_CONF}
else
	echo "Warning: jail configuration file not found, use default settings."
fi

echo "setup jail ${JNAME} using following parameters:"
echo "TARGET=${TARGET}"
echo "TARGET_ARCH=${TARGET_ARCH}"
echo "WITH_32BIT=${WITH_32BIT}"
echo "OSRELEASE=${OSRELEASE}"
echo "BUILDER_JAIL_IP6=${BUILDER_JAIL_IP6}"
echo "BUILDER_JAIL_IP4=${BUILDER_JAIL_IP4}"

RELEASE_TYPE=`echo ${OSRELEASE} | cut -f 2 -d '-' | tr -d [:digit:]`
case ${RELEASE_TYPE} in
"RELEASE"|"BETA"|"RC")
	SUBDIR=releases
	BASE_URL=https://download.FreeBSD.org/ftp/${SUBDIR}/${TARGET}/${TARGET_ARCH}/${OSRELEASE}
	;;
*)
	SUBDIR=snapshot
	JAIL_FBSD_BRANCH=`echo ${OSRELEASE} | cut -f 1 -d '-'`
	JAIL_SVN_REVISION=`echo ${OSRELEASE} | cut -f 2 -d '-'`
	if [ ${JAIL_FBSD_BRANCH} != "head" ]; then
		JAIL_FBSD_BRANCH="${JAIL_FBSD_BRANCH}-${JAIL_SVN_REVISION}"
		JAIL_SVN_REVISION=`echo ${OSRELEASE} | cut -f 3 -d '-'`
	fi
	BASE_URL=https://artifact.ci.FreeBSD.org/${SUBDIR}/${JAIL_FBSD_BRANCH}/${JAIL_SVN_REVISION}/${TARGET}/${TARGET_ARCH}
	;;
esac

fetch -m ${BASE_URL}/base.txz
if [ "${WITH_32BIT}" -eq 1 ]; then
	fetch -m ${BASE_URL}/lib32.txz
fi

sudo zfs create ${ZFS_PARENT}/${JNAME}

sudo tar Jxf base.txz -C ${JPATH}
if [ "${WITH_32BIT}" -eq 1 ]; then
	sudo tar Jxf lib32.txz -C ${JPATH}
fi

if [ -x "${JPATH}/bin/freebsd-version" ]; then
	OSRELEASE=`${JPATH}/bin/freebsd-version -u`
fi

sudo mount -t devfs devfs ${JPATH}/dev
sudo devfs -m ${JPATH}/dev rule -s 4 applyset

sudo mkdir -p ${JPATH}/${WORKSPACE_IN_JAIL}
sudo mount -t nullfs ${WORKSPACE} ${JPATH}/${WORKSPACE_IN_JAIL}

if [ -n "${MOUNT_REPO}" ]; then
	sudo mkdir -p ${JPATH}/usr/${MOUNT_REPO}
	sudo mount -t nullfs ${WORKSPACE}/${MOUNT_REPO} ${JPATH}/usr/${MOUNT_REPO}
fi

printf "${BUILDER_RESOLV_CONF}" | sudo tee ${JPATH}/etc/resolv.conf

if [ "${BUILDER_NETIF}" -a "${BUILDER_JAIL_IP6}" ]; then
	sudo ifconfig ${BUILDER_NETIF} inet6 ${BUILDER_JAIL_IP6} alias
	JAIL_ARG_IP6="ip6.addr=${BUILDER_JAIL_IP6}"
else
	JAIL_ARG_IP6="ip6=disable"
fi
if [ "${BUILDER_NETIF}" -a "${BUILDER_JAIL_IP4}" ]; then
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
	allow.chflags \
	allow.mount \
	allow.mount.devfs \
	enforce_statfs=1 \
	devfs_ruleset=4

echo "setup build environment"

#sudo jexec ${JNAME} sh -c "sed -i.bak -e 's,pkg+http://pkg.FreeBSD.org/\${ABI}/quarterly,pkg+http://pkg.FreeBSD.org/\${ABI}/latest,' /etc/pkg/FreeBSD.conf"
sudo jexec ${JNAME} sh -c "env ASSUME_ALWAYS_YES=yes pkg update"
sudo jexec ${JNAME} sh -c "env pkg install -y `cat freebsd-ci/scripts/jail/default-pkg-list | paste -d ' ' -s -`"
if [ -s "freebsd-ci/jobs/${JOB_NAME}/pkg-list" ]; then
	sudo jexec ${JNAME} sh -c "pkg install -y `cat freebsd-ci/jobs/${JOB_NAME}/pkg-list | paste -d ' ' -s -`"
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

sudo jexec ${JNAME} sh -c "/usr/sbin/pw groupadd jenkins -g 5213"
sudo jexec ${JNAME} sh -c "/usr/sbin/pw useradd jenkins -u 5213 -g 5213 default -c \"Jenkins CI\" -d ${WORKSPACE_IN_JAIL} /bin/sh"
sudo jexec ${JNAME} sh -c "umask 7337; echo 'jenkins ALL=(ALL) NOPASSWD: ALL' > /usr/local/etc/sudoers.d/jenkins"

echo "build environment:"

echo "uname:"
sudo jexec ${JNAME} sh -c "uname -a"
echo "packages:"
sudo jexec ${JNAME} sh -c "pkg info -q"
echo "environment variables:"
sudo jexec -U jenkins ${JNAME} sh -c "env WORKSPACE=${WORKSPACE_IN_JAIL} env"
