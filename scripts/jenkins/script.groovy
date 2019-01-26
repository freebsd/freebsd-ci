date_from = new java.util.GregorianCalendar()
date_from.setTime(new Date().parse("yyyy-mm-dd HH:mm:ss", "2019-01-21 00:00:00"))
date_end = new java.util.GregorianCalendar()
date_end.setTime(new Date().parse("yyyy-mm-dd HH:mm:ss", "2019-01-27 23:59:59"))
url_prefix = "https://ci.freebsd.org/"

def calc_job_statistics(job) {
	total = 0
	success_count = 0
	fail_count = 0
	unstable_count = 0

	println ''
	println "job name: $job.name"

	job.builds.findAll {
		it.timestamp >= date_from && it.timestamp <= date_end
	}.each { build ->
		switch(build.result) {
			case 'SUCCESS':
				success_count++
				break
			case 'FAILURE':
				fail_count++
				println "Failure: " + url_prefix + build.url
				break
			case 'UNSTABLE':
				unstable_count++
				println "Unstable: " + url_prefix + build.url
				break
			default:
				break
		}
		total++
	}

	println "total: $total"
	println "success_count: $success_count"
	println "fail_count: $fail_count"
	println "unstable_count: $unstable_count"
}


job = Jenkins.instance.allItems.findAll { job ->
	job.disabled != true
}.each { job ->
	calc_job_statistics(job)
}
