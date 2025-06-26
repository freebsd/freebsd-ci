#!/bin/sh

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

set -ex

if [ -z "${GIT_COMMIT}" ]; then
	echo "No git commit id specified"
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

KERNCONF=${KERNCONF:-GENERIC}
ARTIFACT_SERVER=${ARTIFACT_SERVER:-artifact.ci.freebsd.org}
ARTIFACT_SUBDIR=snapshot/${FBSD_BRANCH}/${GIT_COMMIT}/${TARGET}/${TARGET_ARCH}
CONFIG_BASE=`dirname $0 | xargs realpath`/config-13
if [ "${KERNCONF}" = "GENERIC" ]; then
	KERNEL=kernel
	KERNEL_DBG=kernel-dbg
	OUTPUT_IMG_NAME=disk-test.img
else
	KERNEL=kernel-${KERNCONF}
	KERNEL_DBG=kernel-dbg-${KERNCONF}
	OUTPUT_IMG_NAME=disk-test-${KERNCONF}.img
fi

sudo rm -fr work
mkdir -p work
cd work

DIST_PACKAGES="base ${KERNEL}"
if [ "${WITH_DOC}" = 1 ]; then
	DIST_PACKAGES="${DIST_PACKAGES} doc"
fi
if [ "${WITH_TESTS}" = 1 ]; then
	DIST_PACKAGES="${DIST_PACKAGES} tests"
fi
if [ "${WITH_DEBUG}" = 1 ]; then
	DIST_PACKAGES="${DIST_PACKAGES} base-dbg ${KERNEL_DBG}"
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
	fetch https://${ARTIFACT_SERVER}/${ARTIFACT_SUBDIR}/${f}.txz
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
	# porch: sys/kern/tty
	# py-dpkt: sys/opencrypto/runtests
	# python3: sys/opencrypto/runtests
	# sudo: tests/sys/cddl/zfs/tests/delegate/...
	# tcptestsuite: network stack test suite
	# sg3_utils: sys/cam/ctl
	sudo chroot ufs pkg install -y	\
		coreutils	\
		gdb		\
		jq		\
		ksh93		\
		nist-kat	\
		nmap		\
		perl5		\
		porch		\
		net/py-dpkt	\
		net/scapy	\
		python		\
		python3		\
		sg3_utils	\
		sudo		\
		tcptestsuite

	if [ "${TARGET}" = "amd64" ]; then
		sudo chroot ufs pkg install -Iy	\
			linux-c7-ltp || true
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

if [ "${TARGET}" = "powerpc" ]; then
	# XXX: Looks like powerpc64 cannot boot with GPT,
	#      and the default fstab specifies /dev/gpt/rootfs.
	cat <<EOF | sudo tee ufs/etc/fstab
# Device        Mountpoint      FStype  Options Dump    Pass#
/dev/vtbd0s3    none            swap    sw      0       0
/dev/vtbd0s2    /               ufs     rw      1       1
fdesc           /dev/fd         fdescfs rw      0       0
EOF
fi

case "${TARGET_ARCH}" in
	mips|mips64|powerpc|powerpcspe|powerpc64)
		B_FLAG="big"
		;;
	*)
		B_FLAG="little"
		;;
esac

sudo dd if=/dev/random of=ufs/boot/entropy bs=4k count=1
sudo makefs -B ${B_FLAG} -d 6144 -t ffs -f 200000 -s 8g -o version=2,bsize=32768,fsize=4096 -Z ufs.img ufs
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
	mips)
		mv ufs.img ${OUTPUT_IMG_NAME}
		;;
	powerpc)
		# Note: BSD slices container is not working when cross created from amd64.
		#       As workaround, add UFS image directly on MBR partition  #2
		mkimg -a 1 -s mbr -f raw \
			-p prepboot:=ufs/boot/boot1.elf \
			-p freebsd:=ufs.img \
			-p freebsd::1G \
			-o ${OUTPUT_IMG_NAME}
		;;
	riscv)
		mkdir -p efi/EFI/BOOT
		cp -f ufs/boot/loader_lua.efi efi/EFI/BOOT/bootriscv64.efi
		sudo makefs -d 6144 -t msdos -s 50m -Z efi.img efi
		mkimg -s gpt -f raw \
			-p efi:=efi.img \
			-p freebsd-swap/swapfs::1G \
			-p freebsd-ufs/rootfs:=ufs.img \
			-o ${OUTPUT_IMG_NAME}
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

zstd --rm ${OUTPUT_IMG_NAME}

cd ${WORKSPACE}
rm -fr artifact
mkdir -p artifact/${ARTIFACT_SUBDIR}
mv work/${OUTPUT_IMG_NAME}.zst artifact/${ARTIFACT_SUBDIR}

echo "USE_GIT_COMMIT=${GIT_COMMIT}" > ${WORKSPACE}/trigger.property
