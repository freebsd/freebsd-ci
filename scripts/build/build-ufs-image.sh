#!/bin/sh

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
sudo /usr/local/sbin/pkg-static -c ${PACKAGE_ROOT}/package install -y ports-mgmt/pkg devel/kyua devel/autoconf shells/bash
sudo /usr/local/sbin/pkg-static -c ${PACKAGE_ROOT}/package delete  -y -f kyua atf lutok
sudo /usr/local/sbin/pkg-static -c ${PACKAGE_ROOT}/package add http://people.freebsd.org/~rodrigc/kyua/pkg/freebsd:11:x86:64/atf-0.20_2.txz  http://people.freebsd.org/~rodrigc/kyua/pkg/freebsd:11:x86:64/lutok-0.4_5.txz http://people.freebsd.org/~rodrigc/kyua/pkg/freebsd:11:x86:64/kyua-0.10,3.txz

sudo rm -fr $WORKSPACE/test.img
sudo makefs -t ffs -s 2g -o label=TESTROOT $WORKSPACE/test.img $WORKSPACE/package
sudo chmod a+w $WORKSPACE/test.img
