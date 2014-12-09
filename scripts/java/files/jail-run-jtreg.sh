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

while getopts "t:" opt; do
    case $opt in
        t )  TESTS="$OPTARG" ;;
        ?)  ;;
    esac
done

if [ -z "${TESTS}" ]; then
    TESTS="nashorn,langtools,hotspot,jdk"
fi


HOME=/root


cd $HOME
tar -xzf jtreg4.1-b10.tar.gz


export JAVA_HOME=/usr/local/openjdk8
export JT_JAVA=/usr/local/openjdk7
export WORKDIR=/wrkdirs/usr/ports/java/openjdk8/work

rm -rf $WORKDIR/jtreg-work
rm -rf $WORKDIR/reports

for PACKAGE in `echo $TESTS | tr ',' ' '`
do
	echo $PACKAGE
	$HOME/jtreg/linux/bin/jtreg \
		-automatic \
		-conc:4 \
		-ea \
		-xml \
    	-jdk:$JAVA_HOME \
    	-agentvm \
    	-verbose:summary \
    	-w $WORKDIR/jtreg-work/$PACKAGE \
    	-r $WORKDIR/reports/$PACKAGE \
    	$WORKDIR/openjdk/$PACKAGE/test 
	killall java
	killall jstatd
done
