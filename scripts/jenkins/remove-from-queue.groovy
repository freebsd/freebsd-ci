import jenkins.model.*
import hudson.model.*

// Target job name to remove from the build queue
def targetName = 'XYZ'

// Access the Jenkins build queue
def queue = Jenkins.instance.queue

// Counter for removed items
def removedCount = 0

// Iterate through the items in the build queue
queue.items.each { item ->
    if (item.task.name == targetName) {
        queue.cancel(item)
        removedCount++
    }
}

// Print summary
println "Total items removed from queue: ${removedCount}"
