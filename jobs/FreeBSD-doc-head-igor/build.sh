#!/bin/sh

OUTPUT=checkstyle-result.xml

export SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt
fetch https://people.freebsd.org/~lwhsu/igor/igor
chmod 755 ./igor

./igor -clntESW -X `find doc/en_US.ISO8859-1 -name \*.xml` >> ${OUTPUT}
