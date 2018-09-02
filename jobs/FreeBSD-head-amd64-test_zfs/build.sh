#!/bin/sh

export TARGET=amd64
export TARGET_ARCH=amd64

# modified freebsd-ci/scripts/test/run-tests.sh:

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

ARTIFACT_SERVER=${ARTIFACT_SERVER:-https://artifact.ci.freebsd.org}
ARTIFACT_SUBDIR=snapshot/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
IMG_NAME=disk-test.img
JOB_DIR=freebsd-ci/jobs/${JOB_NAME}
TEST_BASE=freebsd-ci/scripts/test

TIMEOUT_MS=${BUILD_TIMEOUT:-5400000}
TIMEOUT=$((${TIMEOUT_MS} / 1000))
TIMEOUT_EXPECT=$((${TIMEOUT} - 60))
TIMEOUT_VM=$((${TIMEOUT_EXPECT} - 120))

EXTRA_DISK_NUM=5
BHYVE_EXTRA_DISK_PARAM=""

fetch ${ARTIFACT_SERVER}/${ARTIFACT_SUBDIR}/${IMG_NAME}.xz
xz -fd ${IMG_NAME}.xz

for i in `jot ${EXTRA_DISK_NUM}`; do
	truncate -s 128m disk${i}
	BHYVE_EXTRA_DISK_PARAM="${BHYVE_EXTRA_DISK_PARAM} -s $((i + 3)):0,ahci-hd,disk${i}"
done

DISK_TMP=disktmp
truncate -s 32G ${DISK_TMP}
BHYVE_EXTRA_DISK_PARAM="${BHYVE_EXTRA_DISK_PARAM} -s $((${EXTRA_DISK_NUM} + 4)):0,ahci-hd,${DISK_TMP}"

# prepare meta disk to pass information to testvm
rm -fr meta
mkdir meta
cp -R ${JOB_DIR}/meta/ meta/
for i in ${USE_TEST_SUBR}; do
	cp ${TEST_BASE}/subr/${i} meta/
done
touch meta/auto-shutdown
sh -ex ${TEST_BASE}/create-meta.sh

# run test VM image with bhyve
FBSD_BRANCH_SHORT=`echo ${FBSD_BRANCH} | sed -e 's,.*-,,'`
TEST_VM_NAME="testvm-${FBSD_BRANCH_SHORT}-${TARGET_ARCH}-${BUILD_NUMBER}"
sudo /usr/sbin/bhyvectl --vm=${TEST_VM_NAME} --destroy || true
sudo /usr/sbin/bhyveload -c stdio -m 4096m -d ${IMG_NAME} ${TEST_VM_NAME}
set +e
expect -c "set timeout ${TIMEOUT_EXPECT}; \
	spawn sudo /usr/bin/timeout -k 60 ${TIMEOUT_VM} /usr/sbin/bhyve \
	-c 2 -m 4096m -A -H -P -g 0 \
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

# extract test result
sh -ex ${TEST_BASE}/extract-meta.sh
rm -f test-report.*
mv meta-out/meta/test-report.* .

for i in `jot ${EXTRA_DISK_NUM}`; do
	rm -f disk${i}
done
rm -f ${DISK_TMP}
