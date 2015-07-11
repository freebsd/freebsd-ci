#!/bin/sh

cd src
make -DNO_CLEAN -j 4 buildworld TARGET=amd64
make -DNO_CLEAN -j 4 buildkernel TARGET=amd64
