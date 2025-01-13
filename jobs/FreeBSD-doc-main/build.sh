#!/bin/sh

cd doc
make HUGO_ARGS="--logLevel debug --printPathWarnings"

echo "USE_GIT_COMMIT=${GIT_COMMIT}" > ${WORKSPACE}/trigger.property
