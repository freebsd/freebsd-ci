#!/bin/sh

OUTPUT=checkstyle-result.xml

fetch https://people.freebsd.org/~lwhsu/igor/igor
./igor -clntESW -X `find doc/en_US.ISO8859-1 -name \*.xml` >> ${OUTPUT}
