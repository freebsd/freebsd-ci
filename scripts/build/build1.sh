#!/bin/sh

set -x -e

if [ -z "$WORKSPACE" ]; then
	echo "WORKSPACE environment variable undefined."
	exit 1
fi

if [ -z "$KERNCONF" ]; then
	KERNCONF=GENERIC
fi

export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
mkdir -p ${MAKEOBJDIRPREFIX}

(
cat <<EOF
# Put make.conf entries here
`echo -e "$MAKE_CONF_FILE"`
EOF
) > ${WORKSPACE}/make.conf

set +x
echo "--------------------------------------------------------------"
echo ">>> ${WORKSPACE}/make.conf contains:"
set -x
cat ${WORKSPACE}/make.conf
set +x
echo "--------------------------------------------------------------"
set -x

make -j 4 buildworld __MAKE_CONF=${WORKSPACE}/make.conf
make -j 4 buildkernel __MAKE_CONF=${WORKSPACE}/make.conf KERNCONF=${KERNCONF}

