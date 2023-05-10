update:
	jenkins-jobs --conf jenkins_jobs.ini update . ${JOBS}

test:
	jenkins-jobs --conf jenkins_jobs.ini test . ${JOBS} > /dev/null

dumpconfig:
	@for j in ${JOBS}; do \
		jenkins-jobs --conf jenkins_jobs.ini test . $$j > $$j.xml; \
	done
