#!/bin/sh
#
# Copyright (c) 2014 Craig Rodrigues
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

usage()
{
    echo ""
    echo "$0 CONF=[configuration file]"
    echo ""
}

# Allow users to pass in from the command line
#   $0  A=VAL1 B=VAL2
#
# which will set the A and B variables
for f in $@;
do
    if [ "$f" != ${f%%=*} ]; then
        eval $f
        shift
    fi
done

if [ -z "${CONF}" -o ! -f "${CONF}" ]; then
    usage
    exit 1
fi

. ${CONF}

rm -f /var/tmp/${VM}.vm.stop

(
while true
do  
    if [ -f /var/tmp/${VM}.vm.stop ]; then
        echo ""
        echo "/var/tmp/${VM}.vm.stop exists.  Not starting ${VM}"
        echo ""
        exit 1
    fi
    touch ${CONS_A}
    if [ -e /dev/vmm/${VM} ]; then
    	/usr/sbin/bhyvectl --vm=${VM} --destroy
    fi
    
    echo "Starting BHyve virtual machine named '${VM}'.  Use 'cu -l ${CONS_B}' to access console"
    cmd="/usr/sbin/bhyveload -m ${MEM} -d ${IMG} -c ${CONS_A} ${VM}"
    $cmd
    ret=$?
    if [ $ret -ne 0 ]; then
    	echo "[FAILED]: $cmd"
    	exit $ret
    fi
    ifconfig ${BRIDGE} up
    touch ${CONS_A}
    cmd="/usr/sbin/bhyve -c ${CPU} -m ${MEM} -A -H -P -g 0 -s 0:0,hostbridge -s 1:0,lpc -s 2:0,virtio-net,${TAP},mac=${MAC} -s 3:0,virtio-blk,${IMG} -l com1,${CONS_A} ${VM}"
    $cmd &
    ifconfig ${BRIDGE} up
    sleep 5
    echo "~." | cu -l ${CONS_B}
    wait %1
done
) &
