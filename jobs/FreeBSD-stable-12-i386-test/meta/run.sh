#!/bin/sh

METADIR=/meta
sh -ex ${METADIR}/disable-dtrace-tests.sh
sh -ex ${METADIR}/disable-zfs-tests.sh
sh -ex ${METADIR}/disable-notyet-tests.sh
sh -ex ${METADIR}/run-kyua.sh
