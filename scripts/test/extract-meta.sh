#!/bin/sh

METAOUTDIR=meta-out

rm -fr ${METAOUTDIR}
mkdir ${METAOUTDIR}
tar xvf meta.tar -C ${METAOUTDIR}
