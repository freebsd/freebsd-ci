#!/bin/sh

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

BRANCH=head
TARGET=amd64
TARGET_ARCH=amd64

ARTIFACT_SUBDIR=${BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}

sudo rm -fr work
mkdir -p work
cd work

mkdir -p ufs
for f in base kernel lib32 base-dbg kernel-dbg lib32-dbg doc tests
do
	fetch http://artifact.ci.freebsd.org/snapshot/${ARTIFACT_SUBDIR}/${f}.txz
	sudo tar Jxf ${f}.txz -C ufs
done

cat <<EOF | sudo tee ufs/etc/fstab
# Device        Mountpoint      FStype  Options Dump    Pass#
/dev/gpt/swapfs none            swap    sw      0       0
/dev/gpt/rootfs /               ufs     rw      1       1
EOF

sudo makefs -d 6144 -t ffs -s 16g -o version=2,bsize=32768,fsize=4096 ufs.img ufs
mkimg -s gpt -f raw \
	-b ufs/boot/pmbr \
	-p freebsd-boot/bootfs:=ufs/boot/gptboot \
	-p freebsd-swap/swapfs::1G \
	-p freebsd-ufs/rootfs:=ufs.img \
	-o disk.img
xz -0 disk.img

cd ${WORKSPACE}
rm -fr artifact
mkdir -p artifact/${ARTIFACT_SUBDIR}
mv work/disk.img.xz artifact/${ARTIFACT_SUBDIR}
