#!/bin/sh

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

BRANCH=head
TARGET=amd64
TARGET_ARCH=amd64

ARTIFACT_SUBDIR=${BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
IMG_NAME=disk-test.img

fetch http://artifact.ci.freebsd.org/snapshot/${ARTIFACT_SUBDIR}/${IMG_NAME}.xz
xz -fd ${IMG_NAME}.xz

# run test VM image with bhyve
TEST_VM_NAME=test_vm
sudo /usr/sbin/bhyvectl --vm=${TEST_VM_NAME} --destroy || true
sudo /usr/sbin/bhyveload -c stdio -m 2048m -d ${IMG_NAME} ${TEST_VM_NAME}
sudo /usr/sbin/bhyve -c 2 -m 2048m -A -H -P -g 0 \
	-s 0:0,hostbridge \
	-s 1:0,lpc \
	-s 2:0,ahci-hd,${IMG_NAME} \
	-l com1,stdio \
	test_vm
ps auxwww | grep bhyve # debug
BHYVE_PID=`ps auxwww | grep bhyve | grep ${TEST_VM_NAME} | grep -v grep | grep -v sudo | awk '{ print $2 }'`
while [ 1 ]; do
	ps ${BHYVE_PID} > /dev/null
	rc=$?
	if [ $rc -ne 0 ]; then
		break
	fi
	sleep 1
done
sudo /usr/sbin/bhyvectl --vm=${TEST_VM_NAME} --destroy

# extract test result
TMP_DIR=`mktemp -d`
MD_UNIT=`sudo mdconfig -a -t vnode -f ${IMG_NAME}`
sudo mount /dev/${MD_UNIT}p3 ${TMP_DIR}

cp ${TMP_DIR}/usr/tests/test-report.* .

sudo umount ${TMP_DIR}
sudo mdconfig -d -u ${MD_UNIT}
rm -fr ${TMP_DIR}
