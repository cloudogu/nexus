import groovy.json.JsonSlurper
import org.sonatype.nexus.scheduling.TaskConfiguration
import org.sonatype.nexus.scheduling.TaskSupport

def configurationParameters = new JsonSlurper().parseText(args)

def createBackupOrientDBTask() {
    def taskScheduler = container.lookup(TaskScheduler.class.getName())

    def existingTasks = taskScheduler.listsTasks().findAll { it.getTypeId() == configurationParameters.type && it.getName() == configurationParameters.name }
    existingTasks.collect { it.remove() }

    TaskConfiguration config = taskScheduler.createTaskConfigurationInstance(configurationParameters.type)
    config.setEnabled(configurationParameters.enabled)
    config.setName(configurationParameters.name)
    config.setString("location", configurationParameters.location)

    TaskSupport task = new TaskSupport(true)
    task.configure(config)
    task.call()
}

createBackupOrientDBTask()