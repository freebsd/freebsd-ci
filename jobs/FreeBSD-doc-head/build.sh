#!/bin/sh

cd doc
make

cd en_US.ISO8859-1/htdocs
make -j ${BUILDER_JFLAG}

echo "SVN_REVISION=${SVN_REVISION}" > ${WORKSPACE}/trigger.property
