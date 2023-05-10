update:
	jenkins-jobs --conf jenkins_jobs.ini update . ${JOBS}

test:
	jenkins-jobs --conf jenkins_jobs.ini test . ${JOBS} > /dev/null

dumpconfig:
	@for j in ${JOBS}; do \
		jenkins-jobs --conf jenkins_jobs.ini test . $$j > $$j.xml; \
	done

showjobs:
	@{ jenkins-jobs --conf jenkins_jobs.ini test . > /dev/null; } 2>&1 | awk '/Job name:/ {print $$NF}'
