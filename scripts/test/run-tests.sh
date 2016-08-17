#!/bin/sh

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

ARTIFACT_SUBDIR=${BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
IMG_NAME=disk-test.img

fetch http://artifact.ci.freebsd.org/snapshot/${ARTIFACT_SUBDIR}/${IMG_NAME}.xz
xz -fd ${IMG_NAME}.xz

# run test VM image with bhyve
TEST_VM_NAME=VM-${JOB_NAME}-${BUILD_NUMBER}
sudo /usr/sbin/bhyvectl --vm=${TEST_VM_NAME} --destroy || true
sudo /usr/sbin/bhyveload -c stdio -m 2048m -d ${IMG_NAME} ${TEST_VM_NAME}
set +e
expect -c "set timeout 7200; \
	spawn sudo /usr/sbin/bhyve -c 2 -m 2048m -A -H -P -g 0 \
	-s 0:0,hostbridge \
	-s 1:0,lpc \
	-s 2:0,ahci-hd,${IMG_NAME} \
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

cp ${TMP_DIR}/usr/tests/test-report.* . || true

sudo umount ${TMP_DIR}
sudo mdconfig -d -u ${MD_UNIT}
rm -fr ${TMP_DIR}
