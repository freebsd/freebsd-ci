#!/bin/sh

cd doc
make

cd en_US.ISO8859-1/htdocs
make -j ${BUILDER_JFLAG} PINDEX_OVERRIDE=/dev/null

echo "GIT_COMMIT=${GIT_COMMIT}" > ${WORKSPACE}/trigger.property
