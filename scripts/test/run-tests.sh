#!/bin/sh

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

ARTIFACT_SUBDIR=${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
IMG_NAME=disk-test.img

EXTRA_DISK_NUM=5
BHYVE_EXTRA_DISK_PARAM=""

fetch https://artifact.ci.freebsd.org/snapshot/${ARTIFACT_SUBDIR}/${IMG_NAME}.xz
xz -fd ${IMG_NAME}.xz

for i in `jot ${EXTRA_DISK_NUM}`; do
	truncate -s 128m disk${i}
	BHYVE_EXTRA_DISK_PARAM="${BHYVE_EXTRA_DISK_PARAM} -s $((i + 2)):0,ahci-hd,disk${i}"
done

# run test VM image with bhyve
FBSD_BRANCH_SHORT=`echo ${FBSD_BRANCH} | sed -e 's,.*-,,'`
TEST_VM_NAME="testvm-${FBSD_BRANCH_SHORT}-${TARGET_ARCH}-${BUILD_NUMBER}"
sudo /usr/sbin/bhyvectl --vm=${TEST_VM_NAME} --destroy || true
sudo /usr/sbin/bhyveload -c stdio -m 4096m -d ${IMG_NAME} ${TEST_VM_NAME}
set +e
expect -c "set timeout 5340; \
	spawn sudo /usr/bin/timeout -k 60 5220 /usr/sbin/bhyve \
	-c 2 -m 4096m -A -H -P -g 0 \
	-s 0:0,hostbridge \
	-s 1:0,lpc \
	-s 2:0,ahci-hd,${IMG_NAME} \
	${BHYVE_EXTRA_DISK_PARAM} \
	-l com1,stdio \
	${TEST_VM_NAME}; \
        expect { eof }"
rc=$?
echo "bhyve return code = $rc"
sudo /usr/sbin/bhyvectl --vm=${TEST_VM_NAME} --destroy

# extract test result
TMP_DIR=`mktemp -d`
MD_UNIT=`sudo mdconfig -a -t vnode -f ${IMG_NAME}`
sudo mount /dev/${MD_UNIT}p3 ${TMP_DIR}

rm -f test-report.*
cp ${TMP_DIR}/usr/tests/test-report.* . || true

sudo umount ${TMP_DIR}
sudo mdconfig -d -u ${MD_UNIT}
rm -fr ${TMP_DIR}
rm -f ${IMG_NAME}

for i in `jot ${EXTRA_DISK_NUM}`; do
	rm -f disk${i}
done
