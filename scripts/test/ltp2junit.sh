#!/bin/sh -e

# Script takes Linux Test Project output, usually found in
# /compat/linux/opt/ltp/results, and generates a JUnit file.

if [ $# -ne 2 ]; then
	echo "usage: $0 input-file output-file" > /dev/stderr
	exit 1
fi

cat > $2 << END
<?xml version="1.0" encoding="iso-8859-1"?>
<testsuite>
<properties>
</properties>
END

cat "$1" | awk '
$2 ~ /PASS/ {
	printf("<testcase classname=\"ltp\" name=\"%s\">\n</testcase>\n", $1)
}

$2 ~ /FAIL/ {
	printf("<testcase classname=\"ltp\" name=\"%s\">\n\t<failure message=\"see console log for details\"/>\n</testcase>\n", $1);
}

$2 ~ /CONF/ {
	printf("<testcase classname=\"ltp\" name=\"%s\">\n\t<skipped/>\n</testcase>\n", $1);
}

' >> "$2"

cat >> $2 << END
</testsuite>
END
