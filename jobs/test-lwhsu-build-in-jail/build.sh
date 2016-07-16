#!/bin/sh

cd src
export MAKEOBJDIRPREFIX=/workspace/obj
make -j ${BUILDER_JFLAG} buildworld
make -j ${BUILDER_JFLAG} buildkernel
