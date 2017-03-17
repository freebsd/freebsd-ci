#!/bin/sh

cd doc
make

echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
