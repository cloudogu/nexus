import groovy.json.JsonSlurper
import org.sonatype.nexus.scheduling.TaskConfiguration
import org.sonatype.nexus.scheduling.TaskSupport

def configurationParameters = new JsonSlurper().parseText(args)

def createBackupOrientDBTask() {
    System.println.out("Hello")
}

createBackupOrientDBTask()