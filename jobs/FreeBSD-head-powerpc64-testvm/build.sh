#!/bin/sh

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

TARGET=powerpc
TARGET_ARCH=powerpc64

ARTIFACT_SERVER=${ARTIFACT_SERVER:-https://artifact.ci.freebsd.org}
ARTIFACT_SUBDIR=snapshot/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
OUTPUT_IMG_NAME=disk-test.img

sudo rm -fr work
mkdir -p work
cd work

mkdir -p ufs
for f in base kernel base-dbg kernel-dbg tests
do
	fetch ${ARTIFACT_SERVER}/${ARTIFACT_SUBDIR}/${f}.txz
	sudo tar Jxf ${f}.txz -C ufs
done

sudo cp /etc/resolv.conf ufs/etc/

cat <<EOF | sudo tee ufs/etc/fstab
# Device        Mountpoint      FStype  Options Dump    Pass#
/dev/vtbd0s3 none            swap    sw      0       0
/dev/vtbd0s2 /               ufs     rw      1       1
EOF

cat <<EOF | sudo tee ufs/etc/rc.conf
ifconfig_vtnet0="DHCP"
EOF

cat <<EOF | sudo tee ufs/etc/rc.local
#!/bin/sh -ex
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH
echo
echo "--------------------------------------------------------------"
echo "install kyua dependencies!"
echo "--------------------------------------------------------------"
#env ASSUME_ALWAYS_YES=yes pkg update
echo
echo "--------------------------------------------------------------"
echo "start kyua tests!"
echo "--------------------------------------------------------------"
cd /usr/tests
/usr/bin/kyua test
/usr/bin/kyua report --verbose --results-filter passed,skipped,xfail,broken,failed --output test-report.txt
/usr/bin/kyua report-junit --output=test-report.xml
shutdown -p now
EOF


##############################
### Temporary hack since there's no ELFv2 packages available
cat <<EOF | sudo tee ufs/etc/pkg/FreeBSD.conf
linimon: {
        url: "pkg+http://69.55.238.58/FreeBSD/FreeBSD:13:powerpc64/latest/",
        mirror_type: "srv",
        enabled: yes
}
EOF

sudo rm -f ufs/etc/resolv.conf

sudo dd if=/dev/random of=ufs/boot/entropy bs=4k count=1
sudo makefs -B be -d 6144 -t ffs -f 200000 -s 3g -o version=2,bsize=32768,fsize=4096 ufs.img ufs

# Note: BSD slices container is not working when cross created from amd64.
#       As workaround, add UFS image directly on MBR partition  #2
mkimg -a1 -s mbr -f raw \
	-p prepboot:=ufs/boot/boot1.elf \
	-p freebsd:=ufs.img \
	-p freebsd::1G \
	-o ${OUTPUT_IMG_NAME}

zstd --rm ${OUTPUT_IMG_NAME}

cd ${WORKSPACE}
rm -fr artifact
mkdir -p artifact/${ARTIFACT_SUBDIR}
mv work/${OUTPUT_IMG_NAME}.zst artifact/${ARTIFACT_SUBDIR}

echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
