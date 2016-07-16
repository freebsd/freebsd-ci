#!/bin/sh

export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"

JNAME=${JOB_NAME}

echo "--------------------------------------------------------------"
echo "start build in jail ${JNAME}"
echo "--------------------------------------------------------------"

sudo jexec -U jenkins ${JNAME} sh -c "cd /workspace && sh -x freebsd-ci/jobs/${JOB_NAME}/build.sh"
