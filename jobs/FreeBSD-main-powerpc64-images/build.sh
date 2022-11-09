#!/bin/sh

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

if [ -z "${GIT_COMMIT}" ]; then
	echo "No git commit id specified"
	exit 1
fi

BRANCH=main
TARGET=powerpc
TARGET_ARCH=powerpc64

ARTIFACT_SERVER=${ARTIFACT_SERVER:-artifact.ci.freebsd.org}
ARTIFACT_SUBDIR=${BRANCH}/${GIT_COMMIT}/${TARGET}/${TARGET_ARCH}

sudo rm -fr work
mkdir -p work
cd work

mkdir -p ufs
for f in base kernel lib32 base-dbg kernel-dbg lib32-dbg tests
do
	fetch https://${ARTIFACT_SERVER}/snapshot/${ARTIFACT_SUBDIR}/${f}.txz
	sudo tar Jxf ${f}.txz -C ufs
done

cat <<EOF | sudo tee ufs/etc/fstab
# Device        Mountpoint      FStype  Options Dump    Pass#
/dev/vtbd0s2 none            swap    sw      0       0
/dev/vtbd0s3 /               ufs     rw      1       1
EOF

sudo dd if=/dev/random of=ufs/boot/entropy bs=4k count=1
sudo makefs -B be -d 6144 -t ffs -s 16g -o version=2,bsize=32768,fsize=4096,density=16384 ufs.img ufs


# disk for pseries machine type
mkimg -a1 -s mbr -f qcow2 \
	-p prepboot:=ufs/boot/boot1.elf \
	-p freebsd::1G \
	-p freebsd:=ufs.img \
	-o disk-pseries.qcow2
zstd --rm disk-pseries.qcow2

# disk for apple machine type (i.e.: Apple G5, QEMU mac99)
mkimg -s apm -f qcow2 \
	-p freebsd-boot:=ufs/boot/boot1.hfs \
	-p freebsd-ufs:=ufs.img \
	-o disk-apple.qcow2
zstd --rm disk-apple.qcow2

cd ${WORKSPACE}
rm -fr artifact
mkdir -p artifact/${ARTIFACT_SUBDIR}
mv work/disk.qcow2.zst artifact/${ARTIFACT_SUBDIR}
