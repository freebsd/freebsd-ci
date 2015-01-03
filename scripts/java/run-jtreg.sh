#!/bin/sh
# Copyright (c) 2014, Brian Gardner <openjdk@getsnappy.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice unmodified, this list of conditions, and the following
#    disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

while getopts "v:a:p:t:nk" opt; do
	case $opt in
		v )  VERSION="$OPTARG" ;;
		a )  ARCH="$OPTARG" ;;
		p )  PORTS_TREE="$OPTARG" ;;
		n )  NO_CLEANUP="yes" ;;
		k )  CLEANUP_FIRST="yes" ;;
		t )  TESTS="$OPTARG" ;;
		?)  ;;
	esac
done

usage() 
{
	echo "Usage: $0 -v <version> -a <arch> -p <ports_tree> [-n] [-t <tests>]"
	echo "	-v <version>	: the version should be in the form of svn branches: "
	echo "					  stable/9 or head for current"
	echo "	-a <arch>		: the arch should be i386 or amd64"
	echo "	-p <ports_tree>	: the poudriere ports tree to use, useful for testing openjdk8 patches"
	echo "	-n				: do not cleanup poudriere jails when finished, also useful for testing openjdk8 patches"
	echo "	-k				: cleanup and unmount poudriere jail if it is currently mounted, useful alongside the"
	echo "					  -n switch, to keep jails mounted for debugging between runs while still starting"
	echo "					  with a fresh start."
	echo "	-t <tests>		: run a subset of test projects.  Argument is a comma seperated list of test projects."
	echo "					  available projects are nashorn, langtools, hotspot, and jdk"
	echo "					  defaults to running all test projects"
	echo "Example: $0 -v releng/10.1 -a amd64 -p openjdk8"
	exit 1;
}


if [ -z "${VERSION}" -o -z "${ARCH}" -o -z "${PORTS_TREE}" ]; then
	usage
fi

if [ -z "${TESTS}" ]; then
	TESTS="nashorn,langtools,hotspot,jdk"
fi


if [ -z `which poudriere` ]; then
	echo "$0: poudriere is required in the path"
	exit 1;
fi

JAIL_NAME=`echo ${VERSION}_${ARCH} |  tr "[a-z]/." "[A-Z]__"`
JAIL_PORT=${JAIL_NAME}-${PORTS_TREE}
TMP_DIR=`pwd`
JAVA_CI_DIR=`dirname $0`


if [ "${CLEANUP_FIRST}" == "yes" ]; then
	echo "Cleaning up ${JAIL_PORT}"
	sudo poudriere jail -k -j ${JAIL_NAME} -p ${PORTS_TREE}
fi


if [ -d /usr/local/poudriere/ports/${PORTS_TREE} ]; then
	echo "Updating ports tree ${PORTS_TREE}"
	sudo poudriere ports -u -p ${PORTS_TREE} 
else
	echo "Fetching ports tree ${PORTS_TREE}"
	sudo poudriere ports -c -p ${PORTS_TREE} -m svn
fi

if [ -d /usr/local/poudriere/jails/${JAIL_NAME} ]; then
	INCOMING=`svn diff /usr/local/poudriere/jails/RELENG_10_1_AMD64/usr/src -r BASE:HEAD`
	if [ -z "$INCOMING" ]; then
		echo "Skipping update to jail ${JAIL_NAME}, already up-to-date"
	else
		echo "Updating jail ${JAIL_NAME}"
		sudo poudriere jails -u -j ${JAIL_NAME} -p ${PORTS_TREE} 
	fi
else
	echo "Creating jail ${JAIL_NAME}"
	sudo poudriere jails -c -j ${JAIL_NAME} -p ${PORTS_TREE} -m svn -v ${VERSION}
fi



mkdir -p "${TMP_DIR}"
cd "${TMP_DIR}"



echo "Building openjdk8 and dependencies in ${JAIL_PORT}"
sudo poudriere testport -I  -j ${JAIL_NAME}  -p ${PORTS_TREE} -o java/openjdk8


echo "Preparing ${JAIL_PORT} to run jtreg"
fetch https://adopt-openjdk.ci.cloudbees.com/job/jtreg/lastStableBuild/artifact/jtreg4.1-b10.tar.gz
sudo mv jtreg4.1-b10.tar.gz /usr/local/poudriere/data/build/${JAIL_PORT}/ref/root/
sudo cp ${JAVA_CI_DIR}/files/jail-run-jtreg.sh ${JAVA_CI_DIR}/files/jail-merge-jtreg.sh /usr/local/poudriere/data/build/${JAIL_PORT}/ref/root/

echo "Running jtreg in ${JAIL_PORT} for $TESTS"
sudo jexec ${JAIL_PORT} env -i TERM=${TERM} /root/jail-run-jtreg.sh -t $TESTS

echo "Copying jtreg results to ${TMP_DIR}"
sudo cp -Rp /usr/local/poudriere/data/build/${JAIL_PORT}/ref/wrkdirs/usr/ports/java/openjdk8/work/jtreg-work /usr/local/poudriere/data/build/${JAIL_PORT}/ref/wrkdirs/usr/ports/java/openjdk8/work/reports "${TMP_DIR}"/

#echo "Merging jtreg results"
#sudo jexec ${JAIL_PORT} env -i TERM=${TERM} /root/jail-merge-jtreg.sh -t $TESTS


if [ "${NO_CLEANUP}" != "yes" ]; then
	echo "Cleaning up ${JAIL_PORT}"
	sudo poudriere jail -k -j ${JAIL_NAME} -p ${PORTS_TREE}
fi
