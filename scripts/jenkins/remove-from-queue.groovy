import jenkins.model.*
import hudson.model.*

// Regex pattern to match job names in the queue
def namePattern = ~/^XYZ.*/

// Access the Jenkins build queue
def queue = Jenkins.instance.queue

// Counter for removed items
def removedCount = 0

// Iterate through queued items
queue.items.each { item ->
    def jobName = item.task.name
    if (jobName ==~ namePattern) {
        println "Removing queued item: ${jobName}"
        queue.cancel(item)
        removedCount++
    }
}

// Final summary
println "Total items removed from queue: ${removedCount}"
