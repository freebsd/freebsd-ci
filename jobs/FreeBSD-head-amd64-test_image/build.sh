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
for f in base kernel tests
do
	fetch http://artifact.ci.freebsd.org/snapshot/${ARTIFACT_SUBDIR}/${f}.txz
	sudo tar Jxf ${f}.txz -C ufs
done

cat <<EOF | sudo tee ufs/etc/fstab
# Device        Mountpoint      FStype  Options Dump    Pass#
/dev/ada0p2     none            swap    sw      0       0
/dev/ufs/ROOT   /               ufs     rw      1       1
proc            /proc           procfs  rw      0       0
EOF

cat <<EOF | sudo tee ufs/etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 2610:1c1:1:6002::100
nameserver 2610:1c1:1:6002::200
EOF

sudo makefs -d 6144 -t ffs -f 200000 -s 2g -o version=2,bsize=32768,fsize=4096,label=ROOT ufs.img ufs
mkimg -s gpt -b ufs/boot/pmbr -p freebsd-boot:=ufs/boot/gptboot -p freebsd-swap::1G -p freebsd-ufs:=ufs.img -o disk-test.img
xz -0 disk-test.img

cd /workspace
rm -fr artifact
mkdir -p artifact/${ARTIFACT_SUBDIR}
mv work/disk-test.img.xz artifact/${ARTIFACT_SUBDIR}

echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
