#!/bin/sh

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

set -ex

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

ARTIFACT_SERVER=${ARTIFACT_SERVER:-https://artifact.ci.freebsd.org}
ARTIFACT_SUBDIR=snapshot/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
CONFIG_BASE=`dirname $0 | xargs realpath`/config
OUTPUT_IMG_NAME=disk-test.img

sudo rm -fr work
mkdir -p work
cd work

DIST_PACKAGES="base kernel"
if [ "${WITH_DOC}" = 1 ]; then
	DIST_PACKAGES="${DIST_PACKAGES} doc"
fi
if [ "${WITH_TESTS}" = 1 ]; then
	DIST_PACKAGES="${DIST_PACKAGES} tests"
fi
if [ "${WITH_DEBUG}" = 1 ]; then
	DIST_PACKAGES="${DIST_PACKAGES} base-dbg kernel-dbg"
fi
if [ "${WITH_LIB32}" = 1 ]; then
	DIST_PACKAGES="${DIST_PACKAGES} lib32"
	if [ "${WITH_DEBUG}" = 1 ]; then
		DIST_PACKAGES="${DIST_PACKAGES} lib32-dbg"
	fi
fi
mkdir -p ufs
for f in ${DIST_PACKAGES}
do
	fetch ${ARTIFACT_SERVER}/${ARTIFACT_SUBDIR}/${f}.txz
	sudo tar Jxf ${f}.txz -C ufs
done

sudo cp /etc/resolv.conf ufs/etc/
sudo mount -t devfs devfs ufs/dev
sudo chroot ufs env ASSUME_ALWAYS_YES=yes pkg update
# Install packages needed by tests:
# coreutils: bin/date
# gdb: local/kyua/utils/stacktrace_test
# kyua: everything
# ksh93: tests/sys/cddl/zfs/...
# nist-kat: sys/opencrypto/runtests
# nmap: sys/netinet/fibs_test:arpresolve_checks_interface_fib
# perl5: lots of stuff
# pkgconf: local/lutok/examples_test, local/atf/atf-c, local/atf/atf-c++
# py-dpkt: sys/opencrypto/runtests
# python2: sys/opencrypto/runtests
sudo chroot ufs pkg install -y	\
	devel/gdb		\
	devel/kyua		\
	lang/perl5.30		\
	lang/python2		\
	net/py-dpkt		\
	net/scapy		\
	security/nist-kat	\
	security/nmap		\
	shells/ksh93		\
	sysutils/coreutils

sudo umount ufs/dev
sudo rm -f ufs/etc/resolv.conf

# copy default configs, existing files will be override
sudo cp -Rf ${CONFIG_BASE}/testvm/override/ ufs/

FROM=${CONFIG_BASE}/testvm/append/
TO=ufs
for i in `find ${FROM} -type f`
do
	f=${i#${FROM}}
	sudo mkdir -p ${TO}/`dirname $f`
	cat ${FROM}$f | sudo tee -a ${TO}/$f > /dev/null
done

sudo dd if=/dev/random of=ufs/boot/entropy bs=4k count=1
sudo makefs -d 6144 -t ffs -f 200000 -s 8g -o version=2,bsize=32768,fsize=4096 -Z ufs.img ufs
mkimg -s gpt -f raw \
	-b ufs/boot/pmbr \
	-p freebsd-boot/bootfs:=ufs/boot/gptboot \
	-p freebsd-swap/swapfs::1G \
	-p freebsd-ufs/rootfs:=ufs.img \
	-o ${OUTPUT_IMG_NAME}
xz -0 ${OUTPUT_IMG_NAME}

cd ${WORKSPACE}
rm -fr artifact
mkdir -p artifact/${ARTIFACT_SUBDIR}
mv work/${OUTPUT_IMG_NAME}.xz artifact/${ARTIFACT_SUBDIR}

echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
