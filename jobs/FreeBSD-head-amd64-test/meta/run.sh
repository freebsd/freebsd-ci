#!/bin/sh

METADIR=/meta
sh -ex ${METADIR}/disable-dtrace-tests.sh
sh -ex ${METADIR}/disable-local-tests.sh
sh -ex ${METADIR}/disable-zfs-tests.sh
sh -ex ${METADIR}/run-kyua.sh
