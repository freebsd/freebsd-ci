#!/bin/sh

OUTPUT=checkstyle-result.xml

cat << HEADER > ${OUTPUT}
<?xml version="1.0" encoding="UTF-8"?>
<checkstyle version="5.0">
HEADER

igor -clntESW -X `find doc/en_US.ISO8859-1/books/handbook -name \*.xml` >> ${OUTPUT}

cat << FOOTER >> ${OUTPUT}
</checkstyle>
FOOTER
