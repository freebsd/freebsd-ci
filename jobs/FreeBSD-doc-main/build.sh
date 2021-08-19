#!/bin/sh

cd doc
make HUGO_ARGS="--verbose --debug --path-warnings"

echo "USE_GIT_COMMIT=${GIT_COMMIT}" > ${WORKSPACE}/trigger.property
