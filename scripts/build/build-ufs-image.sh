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

# Jenkins passes parameters to jobs via environment
# variables, so we need to set these before running the
# script.

if [ -z "$WORKSPACE" ]; then
    echo "$WORKSPACE variable is undefined."
    exit 1 
fi

if [ -z "$BUILD_ROOT" ]; then
    echo "$BUILD_ROOT variable is undefined."
    exit 1 
fi

if [ -z "$PACKAGE_ROOT" ]; then
    PACKAGE_ROOT=$WORKSPACE
fi

export MAKEOBJDIRPREFIX=/usr/obj
cd $BUILD_ROOT

sudo rm -fr ${PACKAGE_ROOT}/package
mkdir -p ${PACKAGE_ROOT}/package
sudo make installworld NO_FSCHG=yes DESTDIR=${PACKAGE_ROOT}/package
sudo make  installkernel NO_FSCHG=yes DESTDIR=${PACKAGE_ROOT}/package
sudo make  distribution NO_FSCHG=yes DESTDIR=${PACKAGE_ROOT}/package

cd $WORKSPACE
rm -fr tmp
mkdir -p tmp
(
cat <<EOF
# Device                Mountpoint      FStype  Options         Dump    Pass#
/procfs                 /proc           procfs  rw              0       0
fdesc                   /dev/fd         fdescfs rw              0       0
/dev/ufs/TESTROOT             /            ufs    rw              1       1
EOF
) > tmp/fstab
sudo cp tmp/fstab ${PACKAGE_ROOT}/package/etc/fstab
sudo cp /etc/resolv.conf ${PACKAGE_ROOT}/package/etc/resolv.conf

# This hack is required until local fixes to kyua make it into a release
# version, so we don't have to install our own version of kyua into the image
PKG_ARCHITECTURE=$(pkg info pkg | grep '^Architecture' | awk '{print $NF}')
sudo /usr/local/sbin/pkg-static -c ${PACKAGE_ROOT}/package install -y ports-mgmt/pkg devel/kyua devel/autoconf shells/bash
sudo /usr/local/sbin/pkg-static -c ${PACKAGE_ROOT}/package delete  -y -f kyua atf lutok
sudo /usr/local/sbin/pkg-static -c ${PACKAGE_ROOT}/package add http://people.freebsd.org/~rodrigc/kyua/pkg/${PKG_ARCHITECTURE}/atf-0.20_2.txz  http://people.freebsd.org/~rodrigc/kyua/pkg/${PKG_ARCHITECTURE}/lutok-0.4_5.txz http://people.freebsd.org/~rodrigc/kyua/pkg/${PKG_ARCHITECTURE}/kyua-0.10,3.txz

sudo rm -fr $WORKSPACE/test.img
sudo makefs -t ffs -s 2g -o label=TESTROOT $WORKSPACE/test.img $WORKSPACE/package
sudo chmod a+w $WORKSPACE/test.img
