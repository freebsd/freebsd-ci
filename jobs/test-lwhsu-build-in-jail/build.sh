#!/bin/sh

cd src
make -DNO_CLEAN -j 4 buildworld TARGET=i386
make -DNO_CLEAN -j 4 buildkernel TARGET=i386
