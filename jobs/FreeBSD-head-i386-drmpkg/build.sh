#!/bin/sh

export TARGET=i386
export TARGET_ARCH=i386

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt
VM_MAXCPU=16

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

ARTIFACT_SERVER=${ARTIFACT_SERVER:-artifact.ci.freebsd.org}
ARTIFACT_SUBDIR=snapshot/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
IMG_NAME=disk-base.img
JOB_DIR=freebsd-ci/jobs/${JOB_NAME}
TEST_BASE=${WORKSPACE}/freebsd-ci/scripts/test

TIMEOUT_MS=${BUILD_TIMEOUT:-5400000}
TIMEOUT=$((${TIMEOUT_MS} / 1000))
TIMEOUT_EXPECT=$((${TIMEOUT} - 60))
TIMEOUT_VM=$((${TIMEOUT_EXPECT} - 120))

if [ ${BUILDER_JFLAG} -le ${VM_MAXCPU} ]; then
	VM_CPU_COUNT=${BUILDER_JFLAG}
else
	VM_CPU_COUNT=${VM_MAXCPU}
fi
VM_MEM_SIZE=${BUILDER_MEMORY}

METADIR=meta
METAOUTDIR=meta-out
RUN_RESULT_FILE=${METAOUTDIR}/result

fetch https://${ARTIFACT_SERVER}/${ARTIFACT_SUBDIR}/${IMG_NAME}.zst
zstd --rm -fd ${IMG_NAME}.zst

DISK_ZFS=diskzfs
rm -f ${DISK_ZFS}
truncate -s 32G ${DISK_ZFS}
PKGS_TAR=pkgs.tar
rm -f ${PKGS_TAR}
truncate -s 1G ${PKGS_TAR}

# prepare meta disk to pass information to testvm
rm -fr ${METADIR}
mkdir ${METADIR}
cp -R ${JOB_DIR}/${METADIR}/ ${METADIR}/
printf "${BUILDER_RESOLV_CONF}" > ${METADIR}/resolv.conf
eval BUILDER_JAIL_IP6="\$BUILDER_${EXECUTOR_NUMBER}_IP6"
echo "${BUILDER_JAIL_IP6}" > ${METADIR}/ip
echo "${BUILDER_HTTP_PROXY}" > ${METADIR}/http_proxy
touch ${METADIR}/auto-shutdown
sh -ex ${TEST_BASE}/create-meta.sh

# run test VM image with bhyve
FBSD_BRANCH_SHORT=`echo ${FBSD_BRANCH} | sed -e 's,.*-,,'`
TEST_VM_NAME="testvm-${FBSD_BRANCH_SHORT}-${TARGET_ARCH}-${BUILD_NUMBER}"
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
	-s 4:0,ahci-hd,${DISK_ZFS} \
	-s 5:0,ahci-hd,${PKGS_TAR} \
	-s 6:0,virtio-net,tap${EXECUTOR_NUMBER} \
	-l com1,stdio \
	${TEST_VM_NAME}; \
        expect { eof }"
rc=$?
echo "bhyve return code = $rc"
sudo /usr/sbin/bhyvectl --vm=${TEST_VM_NAME} --destroy

# extract result
sh -ex ${TEST_BASE}/extract-meta.sh

rm -f ${DISK_ZFS}
rm -f ${PKGS_TAR}
rm -f ${IMG_NAME}

if [ -f ${RUN_RESULT_FILE} ]; then
	RESULT=`cat ${RUN_RESULT_FILE}`
	if [ ${RESULT} -ne 0 ]; then
		exit ${RESULT}
	fi
else
	exit 1
fi
