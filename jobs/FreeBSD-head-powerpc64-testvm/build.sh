#!/bin/sh

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

BRANCH=head
TARGET=powerpc
TARGET_ARCH=powerpc64

ARTIFACT_SUBDIR=${BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
OUTPUT_IMG_NAME=disk-test.img

sudo rm -fr work
mkdir -p work
cd work

mkdir -p ufs
for f in base kernel base-dbg kernel-dbg doc tests
do
	fetch https://artifact.ci.freebsd.org/snapshot/${ARTIFACT_SUBDIR}/${f}.txz
	sudo tar Jxf ${f}.txz -C ufs
done

sudo cp /etc/resolv.conf ufs/etc/

cat <<EOF | sudo tee ufs/etc/fstab
# Device        Mountpoint      FStype  Options Dump    Pass#
/dev/da0s3 none            swap    sw      0       0
/dev/da0s2 /               ufs     rw      1       1
EOF

cat <<EOF | sudo tee ufs/etc/rc.conf
ifconfig_llan0="DHCP"
EOF

cat <<EOF | sudo tee ufs/etc/rc.local
#!/bin/sh -ex
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH
echo
echo "--------------------------------------------------------------"
echo "install kyua dependencies!"
echo "--------------------------------------------------------------"
env ASSUME_ALWAYS_YES=yes pkg update
pkg install -y kyua
echo
echo "--------------------------------------------------------------"
echo "start kyua tests!"
echo "--------------------------------------------------------------"
cd /usr/tests
/usr/local/bin/kyua test
/usr/local/bin/kyua report --verbose --results-filter passed,skipped,xfail,broken,failed --output test-report.txt
/usr/local/bin/kyua report-junit --output=test-report.xml
shutdown -p now
EOF

sudo rm -f ufs/etc/resolv.conf

sudo dd if=/dev/random of=ufs/boot/entropy bs=4k count=1
sudo makefs -B be -d 6144 -t ffs -f 200000 -s 2g -o version=2,bsize=32768,fsize=4096 ufs.img ufs

# Note: BSD slices container is not working when cross created from amd64.
#       As workaround, add UFS image directly on MBR partition  #2
mkimg -a1 -s mbr -f raw \
	-p prepboot:=ufs/boot/boot1.elf \
	-p freebsd:=ufs.img \
	-p freebsd::1G \
	-o ${OUTPUT_IMG_NAME}

xz -0 ${OUTPUT_IMG_NAME}

cd ${WORKSPACE}
rm -fr artifact
mkdir -p artifact/${ARTIFACT_SUBDIR}
mv work/${OUTPUT_IMG_NAME}.xz artifact/${ARTIFACT_SUBDIR}

echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
