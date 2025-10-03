#!/bin/sh

export TARGET=amd64
export TARGET_ARCH=amd64

# modified freebsd-ci/scripts/test/run-tests.sh:

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

if [ -z "${GIT_COMMIT}" ]; then
	echo "No git commit id specified"
	exit 1
fi

ARTIFACT_SERVER=${ARTIFACT_SERVER:-artifact.ci.freebsd.org}
ARTIFACT_SUBDIR=snapshot/${FBSD_BRANCH}/${GIT_COMMIT}/${TARGET}/${TARGET_ARCH}
IMG_NAME=disk-test.img
JOB_DIR=freebsd-ci/jobs/${JOB_NAME}
TEST_BASE=freebsd-ci/scripts/test

TIMEOUT_MS=${BUILD_TIMEOUT:-5400000}
TIMEOUT=$((${TIMEOUT_MS} / 1000))
TIMEOUT_EXPECT=$((${TIMEOUT} - 60))
TIMEOUT_VM=$((${TIMEOUT_EXPECT} - 120))

EXTRA_DISK_NUM=5
EXTRA_DISK_SIZE=8G
BHYVE_EXTRA_DISK_PARAM=""

METADIR=meta
METAOUTDIR=meta-out

TEST_VM_MEMORY=8192m

fetch https://${ARTIFACT_SERVER}/${ARTIFACT_SUBDIR}/${IMG_NAME}.zst
zstd --rm -fd ${IMG_NAME}.zst

for i in `jot ${EXTRA_DISK_NUM}`; do
	truncate -s ${EXTRA_DISK_SIZE} disk${i}
	BHYVE_EXTRA_DISK_PARAM="${BHYVE_EXTRA_DISK_PARAM} -s $((i + 3)):0,virtio-blk,disk${i}"
done

DISK_TMP=disktmp
truncate -s 32G ${DISK_TMP}
BHYVE_EXTRA_DISK_PARAM="${BHYVE_EXTRA_DISK_PARAM} -s $((${EXTRA_DISK_NUM} + 4)):0,virtio-blk,${DISK_TMP}"

# prepare meta disk to pass information to testvm
rm -fr ${METADIR}
mkdir ${METADIR}
cp -R ${JOB_DIR}/${METADIR}/ ${METADIR}/
for i in ${USE_TEST_SUBR}; do
	cp ${TEST_BASE}/subr/${i} ${METADIR}/
done
touch ${METADIR}/auto-shutdown
sh -ex ${TEST_BASE}/create-meta.sh

# run test VM image with bhyve
FBSD_BRANCH_SHORT=`echo ${FBSD_BRANCH} | sed -e 's,.*-,,'`
TEST_VM_NAME="testvm-${FBSD_BRANCH_SHORT}-${TARGET_ARCH}-${BUILD_NUMBER}"
sudo /usr/sbin/bhyvectl --vm=${TEST_VM_NAME} --destroy || true
sudo /usr/sbin/bhyveload -c stdio -m ${TEST_VM_MEMORY} -d ${IMG_NAME} ${TEST_VM_NAME}
set +e
expect -c "set timeout ${TIMEOUT_EXPECT}; \
	spawn sudo /usr/bin/timeout -k 60 ${TIMEOUT_VM} /usr/sbin/bhyve \
	-c 2 -m ${TEST_VM_MEMORY} -H -P \
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

# extract test result
sh -ex ${TEST_BASE}/extract-meta.sh
rm -f test-report.*
mv ${METAOUTDIR}/test-report.* .

for i in `jot ${EXTRA_DISK_NUM}`; do
	rm -f disk${i}
done
rm -f ${DISK_TMP}
rm -f ${IMG_NAME}
