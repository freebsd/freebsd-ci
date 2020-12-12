#!/bin/sh

export TARGET=amd64
export TARGET_ARCH=amd64

# modified freebsd-ci/scripts/test/run-tests.sh:

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

ARTIFACT_SERVER=${ARTIFACT_SERVER:-artifact.ci.freebsd.org}
ARTIFACT_SUBDIR=snapshot/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
IMG_NAME=disk-test.img
JOB_DIR=freebsd-ci/jobs/${JOB_NAME}
TEST_BASE=freebsd-ci/scripts/test

TIMEOUT_MS=${BUILD_TIMEOUT:-5400000}
TIMEOUT=$((${TIMEOUT_MS} / 1000))
TIMEOUT_EXPECT=$((${TIMEOUT} - 60))
TIMEOUT_VM=$((${TIMEOUT_EXPECT} - 120))

METADIR=meta
METAOUTDIR=meta-out

TEST_VM_MEMORY=8192m

fetch https://${ARTIFACT_SERVER}/${ARTIFACT_SUBDIR}/${IMG_NAME}.zst
zstd --rm -fd ${IMG_NAME}.zst

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
	-c 2 -m ${TEST_VM_MEMORY} -A -H -P -g 0 \
	-s 0:0,hostbridge \
	-s 1:0,lpc \
	-s 2:0,ahci-hd,${IMG_NAME} \
	-s 3:0,ahci-hd,meta.tar \
	-l com1,stdio \
	${TEST_VM_NAME}; \
        expect { eof }"
rc=$?
echo "bhyve return code = $rc"
sudo /usr/sbin/bhyvectl --vm=${TEST_VM_NAME} --destroy

sh -ex ${TEST_BASE}/extract-meta.sh
sh -ex ${TEST_BASE}/ltp2junit.sh ${METAOUTDIR}/ltp-results.log test-report.xml
rm -f ${IMG_NAME}
