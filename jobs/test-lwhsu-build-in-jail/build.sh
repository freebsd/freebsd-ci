#!/bin/sh

echo "==== env: ===="
env
echo "========"

cd doc
make -j ${BUILDER_JFLAG}
