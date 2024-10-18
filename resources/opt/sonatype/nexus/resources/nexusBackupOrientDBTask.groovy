import org.sonatype.nexus.scheduling.TaskConfiguration
import org.sonatype.nexus.scheduling.TaskSupport
import groovy.json.JsonSlurper


// get parameters from payload JSON file
def configurationParameters = new JsonSlurper().parseText(args)

def createBackupOrientDBTask(configurationParameters) {
    def taskScheduler = container.lookup(TaskScheduler.class.getName())

    def existingTasks = taskScheduler.listsTasks().findAll { it.getTypeId() == configurationParameters.type && it.getName() == configurationParameters.name }
    existingTasks.collect { it.remove() }

    TaskConfiguration config = taskScheduler.createTaskConfigurationInstance(configurationParameters.type)
    config.setEnabled(configurationParameters.enabled.toBoolean())
    config.setName(configurationParameters.name)
    config.setString("location", configurationParameters.location)

    TaskSupport task = new TaskSupport(true)
    task.configure(config)
    task.call()
}

createBackupOrientDBTask(configurationParameters)