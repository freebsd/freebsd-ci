#!/bin/sh

cd doc/documentation
DOC_HTML_ARCHIVE=1 make html
make pdf

echo "USE_GIT_COMMIT=${GIT_COMMIT}" > ${WORKSPACE}/trigger.property
