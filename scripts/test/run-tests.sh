#!/bin/sh

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

ARTIFACT_SERVER=${ARTIFACT_SERVER:-https://artifact.ci.freebsd.org}
ARTIFACT_SUBDIR=snapshot/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
IMG_NAME=disk-test.img
JOB_DIR=freebsd-ci/jobs/${JOB_NAME}
TEST_BASE=`dirname $0`

TIMEOUT_MS=${BUILD_TIMEOUT:-5400000}
TIMEOUT=$((${TIMEOUT_MS} / 1000))
TIMEOUT_EXPECT=$((${TIMEOUT} - 60))
TIMEOUT_VM=$((${TIMEOUT_EXPECT} - 120))

: ${VM_CPU_COUNT:=2}
: ${VM_MEM_SIZE:=4096m}
: ${VM_USE_VIRTIO_BLK:=0}

EXTRA_DISK_NUM=5
BHYVE_EXTRA_DISK_PARAM=""

METADIR=meta
METAOUTDIR=meta-out

fetch ${ARTIFACT_SERVER}/${ARTIFACT_SUBDIR}/${IMG_NAME}.xz
xz -fd ${IMG_NAME}.xz

for i in `jot ${EXTRA_DISK_NUM}`; do
	truncate -s 128m disk${i}
	BHYVE_EXTRA_DISK_PARAM="${BHYVE_EXTRA_DISK_PARAM} -s $((i + 3)):0,ahci-hd,disk${i}"
done

# prepare meta disk to pass information to testvm
rm -fr ${METADIR}
mkdir ${METADIR}
cp -R ${JOB_DIR}/${METADIR}/ ${METADIR}/
for i in ${USE_TEST_SUBR}; do
	cp ${TEST_BASE}/subr/${i} ${METADIR}/
done
touch ${METADIR}/auto-shutdown
sh -ex ${TEST_BASE}/create-meta.sh

FBSD_BRANCH_SHORT=`echo ${FBSD_BRANCH} | sed -e 's,.*-,,'`
TEST_VM_NAME="testvm-${FBSD_BRANCH_SHORT}-${TARGET_ARCH}-${BUILD_NUMBER}"

if [ "${USE_QEMU}" = 1 ]; then
	# run test VM image with qemu
	set +e
	if [ "${VM_USE_VIRTIO_BLK}" = 1 ]; then
		QEMU_DISKS_PARAM="-drive if=none,file=${IMG_NAME},format=raw,id=hd0 \
		    -device virtio-blk-device,drive=hd0 \
		    -drive if=none,file=meta.tar,format=raw,id=hd1 \
		    -device virtio-blk-device,drive=hd1"
	else
		QEMU_DISKS_PARAM="-device ahci,id=ahci \
		    -drive if=none,file=${IMG_NAME},format=raw,id=hd0 \
		    -device ide-hd,drive=hd0,bus=ahci.0 \
		    -drive if=none,file=meta.tar,format=raw,id=hd1 \
		    -device ide-hd,drive=hd1,bus=ahci.1"

	elif
	timeout -k 60 ${TIMEOUT_VM} /usr/local/bin/qemu-system-${QEMU_ARCH} \
		-machine ${QEMU_MACHINE} -smp ${VM_CPU_COUNT} -m ${VM_MEM_SIZE} -nographic \
		${QEMU_EXTRA_PARAM} \
		${QEMU_DRIVE_PARAM}
	rc=$?
	echo "qemu return code = $rc"
else
	# run test VM image with bhyve
	sudo /usr/sbin/bhyvectl --vm=${TEST_VM_NAME} --destroy || true
	sudo /usr/sbin/bhyveload -c stdio -m ${VM_MEM_SIZE} -d ${IMG_NAME} ${TEST_VM_NAME}
	set +e
	expect -c "set timeout ${TIMEOUT_EXPECT}; \
		spawn sudo /usr/bin/timeout -k 60 ${TIMEOUT_VM} /usr/sbin/bhyve \
		-c ${VM_CPU_COUNT} -m ${VM_MEM_SIZE} -A -H -P -g 0 \
		-s 0:0,hostbridge \
		-s 1:0,lpc \
		-s 2:0,ahci-hd,${IMG_NAME} \
		-s 3:0,ahci-hd,meta.tar \
		${BHYVE_EXTRA_DISK_PARAM} \
		-l com1,stdio \
		${TEST_VM_NAME}; \
		expect { eof }"
	rc=$?
	echo "bhyve return code = $rc"
	sudo /usr/sbin/bhyvectl --vm=${TEST_VM_NAME} --destroy
fi

# extract test result
sh -ex ${TEST_BASE}/extract-meta.sh
rm -f test-report.*
mv ${METAOUTDIR}/test-report.* .

for i in `jot ${EXTRA_DISK_NUM}`; do
	rm -f disk${i}
done
rm -f ${IMG_NAME}
