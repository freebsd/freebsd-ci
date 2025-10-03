# Include all configuration directories
CONFIG_DIRS = config macros scm templates projects utilities

update:
	jenkins-jobs --conf jenkins_jobs.ini update $(CONFIG_DIRS) ${JOBS}

test:
	jenkins-jobs --conf jenkins_jobs.ini test $(CONFIG_DIRS) ${JOBS} > /dev/null

dumpconfig:
	@for j in ${JOBS}; do \
		jenkins-jobs --conf jenkins_jobs.ini test $(CONFIG_DIRS) $$j > $$j.xml; \
	done

showjobs:
	@{ jenkins-jobs --conf jenkins_jobs.ini test $(CONFIG_DIRS) > /dev/null; } 2>&1 | awk '/Job name:/ {print $$NF}'
