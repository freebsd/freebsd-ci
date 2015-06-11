#!/bin/sh

cd src
make -DNO_CLEAN -j 4 buildworld TARGET=arm64
make -DNO_CLEAN -j 4 buildkernel TARGET=arm64
