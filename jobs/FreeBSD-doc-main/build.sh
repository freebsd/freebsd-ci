#!/bin/sh

cd doc
make HUGO_ARGS="--verbose --debug --printPathWarnings"

echo "USE_GIT_COMMIT=${GIT_COMMIT}" > ${WORKSPACE}/trigger.property
