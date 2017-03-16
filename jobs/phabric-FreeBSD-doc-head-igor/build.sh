#!/bin/sh

OUTPUT=checkstyle-result.xml

echo DIFF_ID=${DIFF_ID}
echo PHID=${PHID}

igor -clntESW -X `find doc/en_US.ISO8859-1 -name \*.xml` > ${OUTPUT}
