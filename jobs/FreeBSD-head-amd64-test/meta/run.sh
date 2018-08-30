#!/bin/sh

METADIR=/tmp/meta
sh -ex ${METADIR}/disable-zfs-tests.sh 
sh -ex ${METADIR}/run-kyua.sh
