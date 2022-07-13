import org.sonatype.nexus.scheduling.TaskScheduler
import org.sonatype.nexus.scheduling.TaskConfiguration
import groovy.json.JsonSlurper


// get parameters from payload JSON file
def configurationParameters = new JsonSlurper().parseText(args)

def createCompactBlobstoreTask(configurationParameters) {
    def taskScheduler = container.lookup(TaskScheduler.class.getName())

    def allreadyExistingTask = taskScheduler.getTaskByTypeId(configurationParameters.type)
    if (allreadyExistingTask) {
        // already defined this kind of task
        return
    }

    TaskConfiguration config = taskScheduler.createTaskConfigurationInstance(configurationParameters.type)
    config.enabled = configurationParameters.enabled
    config.name = configurationParameters.name
    def propertiesMap = [:]
    propertiesMap.put("blobstoreName": configurationParameters.blobstore)
    config.properties = propertiesMap


    Calendar today = Calendar.getInstance();
    today.clear(Calendar.HOUR); today.clear(Calendar.MINUTE); today.clear(Calendar.SECOND);
    Date todayDate = today.getTime();

    taskScheduler.scheduleTask(config, taskScheduler.scheduleFactory.cron(todayDate, configurationParameters.cron))
}

createCompactBlobstoreTask(configurationParameters)