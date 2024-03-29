import org.sonatype.nexus.scheduling.TaskScheduler
import org.sonatype.nexus.scheduling.TaskConfiguration
import groovy.json.JsonSlurper


// get parameters from payload JSON file
def configurationParameters = new JsonSlurper().parseText(args)

def createCompactBlobstoreTask(configurationParameters) {
    def taskScheduler = container.lookup(TaskScheduler.class.getName())

    def existingTasks = taskScheduler.listsTasks().findAll { it.getTypeId() == configurationParameters.type && it.getName() == configurationParameters.name }
    existingTasks.collect { it.remove() }

    TaskConfiguration config = taskScheduler.createTaskConfigurationInstance(configurationParameters.type)
    config.setEnabled(configurationParameters.enabled.toBoolean())
    config.setName(configurationParameters.name)
    config.setString("blobstoreName", configurationParameters.blobstore)

    Calendar today = Calendar.getInstance();
    today.clear(Calendar.HOUR); today.clear(Calendar.MINUTE); today.clear(Calendar.SECOND);
    Date todayDate = today.getTime();

    taskScheduler.scheduleTask(config, taskScheduler.scheduleFactory.cron(todayDate, configurationParameters.cron))
}

createCompactBlobstoreTask(configurationParameters)