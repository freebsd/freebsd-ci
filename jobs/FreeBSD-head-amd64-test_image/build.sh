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

sudo makefs -d 6144 -t ffs -f 200000 -s 2g -o version=2,bsize=32768,fsize=4096,label=ROOT ufs.img ufs
mkimg -s gpt -b ufs/boot/pmbr -p freebsd-boot:=ufs/boot/gptboot -p freebsd-swap::1G -p freebsd-ufs:=ufs.img -o disk-test.img
xz -0 disk-test.img

cd /workspace
rm -fr artifact
mkdir -p artifact/${ARTIFACT_SUBDIR}
mv work/disk-test.img.xz artifact/${ARTIFACT_SUBDIR}
