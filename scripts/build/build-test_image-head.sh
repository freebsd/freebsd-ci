#!/bin/sh

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

set -ex

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

cleanup () {
	# check mount point inside jail
	P=${WORKSPACE}/work/ufs/dev
	if [ `mount | grep ${P} | wc -l` -gt 0 ]; then
		sudo umount ${P}
	fi
}

trap cleanup EXIT

ARTIFACT_SERVER=${ARTIFACT_SERVER:-https://artifact.ci.freebsd.org}
ARTIFACT_SUBDIR=snapshot/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
CONFIG_BASE=`dirname $0 | xargs realpath`/config-head
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

# Install packages in the target image.  We can only do it
# if we can execute target architecture binaries.
if [ "${TARGET}" = "amd64" -o "${TARGET}" = "i386" ]; then
	sudo cp /etc/resolv.conf ufs/etc/
	sudo mount -t devfs devfs ufs/dev
	sudo chroot ufs env ASSUME_ALWAYS_YES=yes pkg update
	# Install packages needed by tests:
	# coreutils: bin/date
	# gdb: local/kyua/utils/stacktrace_test
	# jq: sys/net/if_bridge_test
	# kyua: everything
	# ksh93: tests/sys/cddl/zfs/...
	# nist-kat: sys/opencrypto/runtests
	# nmap: sys/netinet/fibs_test:arpresolve_checks_interface_fib
	# perl5: lots of stuff
	# pkgconf: local/lutok/examples_test, local/atf/atf-c, local/atf/atf-c++
	# py-dpkt: sys/opencrypto/runtests
	# python2: sys/opencrypto/runtests
	# sudo: tests/sys/cddl/zfs/tests/delegate/...
	sudo chroot ufs pkg install -y	\
		coreutils	\
		gdb		\
		jq		\
		ksh93		\
		kyua		\
		nist-kat	\
		nmap		\
		perl5		\
		py37-dpkt	\
		py37-scapy	\
		python		\
		python2		\
		sudo

	if [ "${TARGET}" = "amd64" ]; then
		sudo chroot ufs pkg install -Iy	\
			linux-c7-ltp
	fi

	sudo umount ufs/dev
	sudo rm -f ufs/etc/resolv.conf
fi

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
case "${TARGET}" in
	arm64)
		mkdir -p efi/EFI/BOOT
		cp -f ufs/boot/loader_lua.efi efi/EFI/BOOT/bootaa64.efi
		sudo makefs -d 6144 -t msdos -s 50m -Z efi.img efi
		mkimg -s gpt -f raw \
			-p efi:=efi.img \
			-p freebsd-swap/swapfs::1G \
			-p freebsd-ufs/rootfs:=ufs.img \
			-o ${OUTPUT_IMG_NAME}
		;;
	arm)
		mkdir -p efi/EFI/BOOT
		cp -f ufs/boot/loader_lua.efi efi/EFI/BOOT/bootarm.efi
		sudo makefs -d 6144 -t msdos -s 50m -Z efi.img efi
		mkimg -s gpt -f raw \
			-p efi:=efi.img \
			-p freebsd-swap/swapfs::1G \
			-p freebsd-ufs/rootfs:=ufs.img \
			-o ${OUTPUT_IMG_NAME}
		;;
	mips|riscv)
		mv ufs.img ${OUTPUT_IMG_NAME}
		;;
	*)
		mkimg -s gpt -f raw \
			-b ufs/boot/pmbr \
			-p freebsd-boot/bootfs:=ufs/boot/gptboot \
			-p freebsd-swap/swapfs::1G \
			-p freebsd-ufs/rootfs:=ufs.img \
			-o ${OUTPUT_IMG_NAME}
		;;
esac

xz -0 ${OUTPUT_IMG_NAME}

cd ${WORKSPACE}
rm -fr artifact
mkdir -p artifact/${ARTIFACT_SUBDIR}
mv work/${OUTPUT_IMG_NAME}.xz artifact/${ARTIFACT_SUBDIR}

echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
