#!/bin/sh

cd doc
make -j 2

echo "GIT_COMMIT=${GIT_COMMIT}" > ${WORKSPACE}/trigger.property
