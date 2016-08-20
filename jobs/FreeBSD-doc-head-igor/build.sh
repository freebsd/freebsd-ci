#!/bin/sh

OUTPUT=checkstyle-result.xml

igor -clntESW -X `find doc/en_US.ISO8859-1 -name \*.xml` >> ${OUTPUT}
