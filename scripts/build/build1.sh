#!/bin/sh
# Copyright (c) 2014, Craig Rodrigues <rodrigc@FreeBSD.org>
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
set -x -e

if [ -z "$WORKSPACE" ]; then
	echo "WORKSPACE environment variable undefined."
	exit 1
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
make -j 4 buildkernel __MAKE_CONF=${WORKSPACE}/make.conf

