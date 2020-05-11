#!/bin/sh

cd doc
make

cd en_US.ISO8859-1/htdocs
make -j ${BUILDER_JFLAG} PINDEX_OVERRIDE=/dev/null

echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
