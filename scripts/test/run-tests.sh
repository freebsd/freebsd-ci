#!/bin/sh

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

if [ -z "${GIT_COMMIT}" ]; then
	echo "No git commit id specified"
	exit 1
fi

_GIT_COMMIT="${GIT_COMMIT}"

if [ ! -z "${USE_GIT_COMMIT}" -a "${USE_GIT_COMMIT}" != "${GIT_COMMIT}" ]; then
	echo "GIT_COMMIT ${GIT_COMMIT} does not match USE_GIT_COMMIT ${USE_GIT_COMMIT}, use USE_GIT_COMMIT for test"
	_GIT_COMMIT="${USE_GIT_COMMIT}"
fi

KERNCONF=${KERNCONF:-GENERIC}
ARTIFACT_SERVER=${ARTIFACT_SERVER:-artifact.ci.freebsd.org}
ARTIFACT_SUBDIR=snapshot/${FBSD_BRANCH}/${_GIT_COMMIT}/${TARGET}/${TARGET_ARCH}
if [ "${KERNCONF}" = "GENERIC" ]; then
	IMG_NAME=disk-test.img
else
	IMG_NAME=disk-test-${KERNCONF}.img
fi
JOB_DIR=freebsd-ci/jobs/${JOB_NAME}
TEST_BASE=`dirname $0`

TIMEOUT_MS=${BUILD_TIMEOUT:-5400000}
TIMEOUT=$((${TIMEOUT_MS} / 1000))
TIMEOUT_EXPECT=$((${TIMEOUT} - 60))
TIMEOUT_VM=$((${TIMEOUT_EXPECT} - 120))

: ${VM_CPU_COUNT:=2}
: ${VM_MEM_SIZE:=8192m}

EXTRA_DISK_NUM=5
BHYVE_EXTRA_DISK_PARAM=""

METADIR=meta
METAOUTDIR=meta-out

fetch https://${ARTIFACT_SERVER}/${ARTIFACT_SUBDIR}/${IMG_NAME}.zst
zstd --rm -fd ${IMG_NAME}.zst

# for cam(4) tests
truncate -s 128m disk-cam
BHYVE_EXTRA_DISK_PARAM="${BHYVE_EXTRA_DISK_PARAM} -s 4:0,ahci-hd,disk-cam"

for i in `jot ${EXTRA_DISK_NUM}`; do
	truncate -s 128m disk${i}
	BHYVE_EXTRA_DISK_PARAM="${BHYVE_EXTRA_DISK_PARAM} -s $((i + 4)):0,virtio-blk,disk${i}"
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

	: ${QEMU_DEVICES:="-device virtio-blk,drive=hd0 -device virtio-blk,drive=hd1"}
	timeout -k 60 ${TIMEOUT_VM} /usr/local/bin/qemu-system-${QEMU_ARCH} \
		-machine ${QEMU_MACHINE} \
		-smp ${VM_CPU_COUNT} \
		-m ${VM_MEM_SIZE} \
		-nographic \
		-no-reboot \
		${QEMU_EXTRA_PARAM} \
		-drive if=none,file=${IMG_NAME},format=raw,id=hd0 \
		-drive if=none,file=meta.tar,format=raw,id=hd1 \
		${QEMU_DEVICES}
	rc=$?
	echo "qemu return code = $rc"
else
	# run test VM image with bhyve
	sudo /usr/sbin/bhyvectl --vm=${TEST_VM_NAME} --destroy || true
	sudo /usr/sbin/bhyveload -c stdio -m ${VM_MEM_SIZE} -d ${IMG_NAME} ${TEST_VM_NAME}
	set +e
	expect -c "set timeout ${TIMEOUT_EXPECT}; \
		spawn sudo /usr/bin/timeout -k 60 ${TIMEOUT_VM} /usr/sbin/bhyve \
		-c ${VM_CPU_COUNT} -m ${VM_MEM_SIZE} -A -H -P \
		-s 0:0,hostbridge \
		-s 1:0,lpc \
		-s 2:0,virtio-blk,${IMG_NAME} \
		-s 3:0,virtio-blk,meta.tar \
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

# Turn known test failures into xfails.
report="test-report.xml"
if [ -e ${JOB_DIR}/xfail-list -a -e "${report}" ]; then
	while IFS=":" read classname name; do
		xpath="/testsuite/testcase[@classname=\"${classname}\"][@name=\"${name}\"]"
		if ! xml sel -Q -t -c "${xpath}/*[self::error or self::failure]" "${report}"; then
			if ! xml sel -Q -t -c "${xpath}" "${report}"; then
				echo "Testcase ${classname}:${name} vanished"
			else
				echo "Testcase ${classname}:${name} unexpectedly succeeded"
			fi
		else
			xml ed -P -L -r "${xpath}/*[self::error or self::failure]" -v skipped "${report}"
		fi
	done < ${JOB_DIR}/xfail-list
fi

rm -f disk-cam
for i in `jot ${EXTRA_DISK_NUM}`; do
	rm -f disk${i}
done
rm -f ${IMG_NAME}
