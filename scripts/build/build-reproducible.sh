diffoscope --html ${WORKSPACE}/diff.html ${WORKSPACE}/obj ${WORKSPACE}/objtest
if [ -f "${WORKSPACE}/diff.html" ]; then
	sudo mkdir -p ${ARTIFACT_DEST}
	mv ${ARTIFACT} ${ARTIFACT_DEST}
	exit 1
else
	exit 0
fi
