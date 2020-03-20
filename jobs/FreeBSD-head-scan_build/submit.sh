#!/bin/sh
#
# Usage: ./submit.sh <input directory> <output directory> <URL>

INPUT="$1"
BUILD="$2"
URL="$3"

if test -z "$URL"; then
	URL="https://freebsd.sp.backtrace.io:6098/post?format=json&token=<token>"
fi

# The default number of reports to include in every chunk.
CHUNK_SIZE=200

mkdir -p "$BUILD/archives"

SIZE_LIMIT="1000000c"

REPORTS_COUNT=`find $1 -name '*.html' -size -${SIZE_LIMIT} | wc -l`
echo "Found $REPORTS_COUNT reports meeting size criteria..."

# We limit individual report size for now, this will be removed in the future.
find $1 -name '*.html' -size -${SIZE_LIMIT} | split -l $CHUNK_SIZE - $BUILD/chunk.

CHUNK_COUNT=`find $BUILD -maxdepth 1 -type f -name "chunk.*" | wc -l`

echo "Generating $CHUNK_COUNT chunks..."

counter=1
for i in `find $BUILD/ -maxdepth 1 -type f -name "chunk.*"`; do
	CHUNK=`basename $i`

	echo "    + $counter [${CHUNK}]"
	counter=`expr $counter + 1`

	tar cTfz "$i" "${BUILD}/archives/${CHUNK}.tar.gz" 
done

rm -f ${BUILD}/chunk.*

echo "Submitting $CHUNK_COUNT chunks..."

counter=1

#QUERY_STRING="author=${CHANGE_AUTHOR}&build_id=${BUILD_ID}&build_number=${BUILD_NUMBER}&job_name=${JOB_NAME}&build_url=${BUILD_URL}&svn_revision=${SVN_REVISION}"

for i in `find $BUILD/archives -type f -name '*.tar.gz'`; do
	CHUNK=`basename $i`

	echo "    + $counter [${CHUNK}]"
	counter=`expr $counter + 1`

	curl -v -X POST https://sca.backtrace.io/api/sca/submit/clang-analyzer?$QUERY_STRING	\
	  -H 'Content-Type: multipart/form-data'						\
	  -F report="@${i}" 									\
	  -F "submitUrl=${URL}"
done

