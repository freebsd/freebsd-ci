#!/bin/sh
# Copyright (c) 2014, Craig Rodrigues <rodrigc@FreeBSD.org>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice unmodified, this list of conditions, and the following
#    disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set -e
set -x

# Jenkins passes parameters to jobs via environment
# variables, so we need to set these before running the
# script.

if [ -z "$WORKSPACE" ]; then
    echo "WORKSPACE variable is undefined."
    exit 1
fi

if [ -z "$BUILD_ROOT" ]; then
    BUILD_ROOT="$WORKSPACE"
fi

if [ -z "$MAKEOBJDIRPREFIX" ]; then
	export MAKEOBJDIRPREFIX=${BUILD_ROOT}/obj
fi

if [ -z "$PACKAGE_ROOT" ]; then
    PACKAGE_ROOT=${WORKSPACE}/package/$(basename ${BUILD_ROOT})
fi

if [ -z "$IMAGE_ROOT" ]; then
    IMAGE_ROOT=${WORKSPACE}/image/$(basename ${BUILD_ROOT})
fi

if [ -n "$ENDIAN" ]; then
	BFLAG="-B $ENDIAN"
fi

cd $BUILD_ROOT

if [ -z "$__MAKE_CONF" ]; then
    if [ -f $WORKSPACE/make.conf ]; then
        __MAKE_CONF=$WORKSPACE/make.conf
    else
        __MAKE_CONF=/etc/make.conf
    fi
fi

sudo rm -fr ${PACKAGE_ROOT}
mkdir -p ${PACKAGE_ROOT}
sudo env MAKEOBJDIRPREFIX=$MAKEOBJDIRPREFIX make installworld NO_FSCHG=yes DESTDIR=${PACKAGE_ROOT} __MAKE_CONF=${__MAKE_CONF}
sudo env MAKEOBJDIRPREFIX=$MAKEOBJDIRPREFIX make  installkernel NO_FSCHG=yes DESTDIR=${PACKAGE_ROOT} __MAKE_CONF=${__MAKE_CONF}
sudo env MAKEOBJDIRPREFIX=$MAKEOBJDIRPREFIX make  distribution NO_FSCHG=yes DESTDIR=${PACKAGE_ROOT} __MAKE_CONF=${__MAKE_CONF}

if [ -z "$FSTAB" ]; then
    FSTAB="
# Device                Mountpoint      FStype  Options         Dump    Pass#
/procfs                 /proc           procfs  rw              0       0
fdesc                   /dev/fd         fdescfs rw              0       0
/dev/ufs/TESTROOT             /            ufs    rw              1       1
"
fi

if [ -z "$RC_CONF" ]; then
    RC_CONF="
sshd_enable=\"YES\"
"
fi

cd $WORKSPACE
sudo rm -fr tmp
mkdir -p tmp
(
cat <<EOF
$FSTAB
EOF
) > tmp/fstab
sudo cp tmp/fstab ${PACKAGE_ROOT}/etc/fstab
sudo cp /etc/resolv.conf ${PACKAGE_ROOT}/etc/resolv.conf

(
cat <<EOF
$RC_CONF
EOF
) > tmp/rc.conf

if [ -n "$CONFIG_JSON" ]; then
    INTERFACE=$(python -c "import json; f = open('$CONFIG_JSON', 'r'); j = json.load(f); print(j['interface'])")
    IP=$(python -c "import json; f = open('$CONFIG_JSON', 'r'); j = json.load(f); print(j['ip'])")
    (
cat <<EOF
ifconfig_${INTERFACE}="inet $IP/24"
EOF
    ) >> tmp/rc.conf
fi

sudo cp tmp/rc.conf ${PACKAGE_ROOT}/etc/rc.conf
sudo cp ${PACKAGE_ROOT}/etc/ssh/sshd_config tmp/sshd_config
sed -i "" -e '/PermitRootLogin/d' tmp/sshd_config
(
cat <<EOF

## Additional SSH settings, added by $(whoami) on $(date)
PermitRootLogin yes
EOF
) >> tmp/sshd_config

sudo cp tmp/sshd_config ${PACKAGE_ROOT}/etc/ssh/sshd_config
sudo chroot ${PACKAGE_ROOT} /bin/sh -c 'echo test | pw mod user root -h 0'

if [ -z "$SKIP_INSTALL_PKG" ]; then
	sudo /usr/local/sbin/pkg-static -c ${PACKAGE_ROOT} install -y ports-mgmt/pkg devel/kyua devel/autoconf shells/bash
fi

if [ -n "$INSTALL_PORTS_TREE" ]; then
	if [ -z "$PORTSDIR" ]; then
		export PORTSDIR=${BUILD_ROOT}/usr/ports
	fi
	# copy the ports tree into the image
	sudo rsync -a $PORTSDIR/ ${PACKAGE_ROOT}/usr/ports

	# Get the distfiles for some packages we need to build inside the
	# image
	sudo make -C ${PACKAGE_ROOT}/usr/ports/devel/kyua fetch-recursive PORTSDIR=${PACKAGE_ROOT}/usr/ports
fi

sudo rm -fr ${IMAGE_ROOT}
sudo mkdir -p ${IMAGE_ROOT}
sudo rm -fr ${IMAGE_ROOT}/test.img
sudo makefs ${BFLAG} -d 6144 -t ffs -f 200000 -s 2g -o version=2,bsize=32768,fsize=4096,label=TESTROOT ${IMAGE_ROOT}/test.img $PACKAGE_ROOT
sudo chmod a+w $IMAGE_ROOT/test.img
