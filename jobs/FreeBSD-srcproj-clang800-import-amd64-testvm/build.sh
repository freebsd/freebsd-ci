#!/bin/sh

export JFLAG=${BUILDER_JFLAG}

export TARGET=amd64
export TARGET_ARCH=amd64

export WITH_LIB32=1
export WITH_DEBUG=1
export WITH_TESTS=1

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

set -ex

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

ARTIFACT_SERVER=${ARTIFACT_SERVER:-http://artifact.ci.freebsd.org}
ARTIFACT_SUBDIR=snapshot/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
CONFIG_BASE=${WORKSPACE}/freebsd-ci/scripts/build/config
OUTPUT_IMG_NAME=disk-test.img

sudo rm -fr work
mkdir -p work
cd work

DIST_PACKAGES="base kernel"
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
sudo mkdir -p ufs/usr/local/etc/pkg/repos
cat ${WORKSPACE}/`dirname $0`/ci-pkg-repo.conf \
	| sed -e "s,%%ARTIFACT_SERVER%%,${ARTIFACT_SERVER}," \
	-e "s,%%ARTIFACT_SUBDIR%%,${ARTIFACT_SUBDIR}," \
	| sudo tee ufs/usr/local/etc/pkg/repos/ci.conf
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
# python: sys/opencrypto
sudo chroot ufs pkg install -y coreutils gdb kyua ksh93 nist-kat nmap perl5 scapy python
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

sudo makefs -d 6144 -t ffs -f 200000 -s 8g -o version=2,bsize=32768,fsize=4096 -Z ufs.img ufs
mkimg -s gpt -f raw \
	-b ufs/boot/pmbr \
	-p freebsd-boot/bootfs:=ufs/boot/gptboot \
	-p freebsd-swap/swapfs::1G \
	-p freebsd-ufs/rootfs:=ufs.img \
	-o ${OUTPUT_IMG_NAME}
zstd --rm ${OUTPUT_IMG_NAME}

cd ${WORKSPACE}
rm -fr artifact
mkdir -p artifact/${ARTIFACT_SUBDIR}
mv work/${OUTPUT_IMG_NAME}.zst artifact/${ARTIFACT_SUBDIR}

echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
