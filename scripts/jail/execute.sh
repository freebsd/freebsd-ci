#!/bin/sh

. freebsd-ci/scripts/jail/jail.conf

JNAME=${JOB_NAME}

echo "--------------------------------------------------------------"
echo "start build in jail ${JNAME}"
echo "--------------------------------------------------------------"

sudo jexec -U jenkins ${JNAME} sh -c "cd /workspace && sh -ex freebsd-ci/jobs/${JOB_NAME}/build.sh"
