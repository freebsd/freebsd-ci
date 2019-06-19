#!/bin/sh

TARGET=amd64
TARGET_ARCH=amd64
WITH_LIB32=1
WITH_DEBUG=1
WITH_TESTS=1

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

set -ex

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

ARTIFACT_SUBDIR=${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
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
	fetch https://artifact.ci.freebsd.org/dtrace-test/${ARTIFACT_SUBDIR}/${f}.txz
	sudo tar Jxf ${f}.txz -C ufs
done

sudo cp /etc/resolv.conf ufs/etc/
sudo mount -t devfs devfs ufs/dev
sudo chroot ufs env ASSUME_ALWAYS_YES=yes pkg update
sudo chroot ufs pkg install -y kyua perl5 pdksh nmap
sudo umount ufs/dev

cat <<EOF | sudo tee ufs/etc/fstab
# Device        Mountpoint      FStype  Options Dump    Pass#
/dev/gpt/swapfs none            swap    sw      0       0
/dev/gpt/rootfs /               ufs     rw      1       1
fdesc           /dev/fd         fdescfs rw      0       0
EOF

cat <<EOF | sudo tee ufs/etc/rc.local
#!/bin/sh -ex
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH
echo
echo "--------------------------------------------------------------"
echo "start kyua tests!"
echo "--------------------------------------------------------------"
cd /usr/tests/cddl/usr.sbin/dtrace
/usr/local/bin/kyua test
/usr/local/bin/kyua report --verbose --results-filter passed,skipped,xfail,broken,failed --output test-report.txt
/usr/local/bin/kyua report-junit --output=test-report.xml
shutdown -p now
EOF

sudo rm -f ufs/etc/resolv.conf

sudo dd if=/dev/random of=ufs/boot/entropy bs=4k count=1
sudo makefs -d 6144 -t ffs -f 200000 -s 4g -o version=2,bsize=32768,fsize=4096 -Z ufs.img ufs
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
