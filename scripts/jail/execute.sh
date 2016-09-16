#!/bin/sh

. freebsd-ci/scripts/jail/jail.conf

JNAME=${JOB_NAME}

echo "--------------------------------------------------------------"
echo "start build in jail ${JNAME}"
echo "--------------------------------------------------------------"

sudo jexec -U jenkins ${JNAME} sh -c "cd ${WORKSPACE_IN_JAIL} && env WORKSPACE=${WORKSPACE_IN_JAIL} sh -ex freebsd-ci/jobs/${JOB_NAME}/build.sh"
