import org.sonatype.nexus.scheduling.internal.TaskFactoryImpl
import org.sonatype.nexus.scheduling.TaskScheduler
import org.sonatype.nexus.scheduling.TaskConfiguration
import groovy.json.JsonSlurper


// get parameters from payload JSON file
def configurationParameters = new JsonSlurper().parseText(args)

def createCompactBlobstoreTask() {
    try {
        def taskScheduler = container.lookup(TaskScheduler.class.getName())

        TaskConfiguration config = taskScheduler.createTaskConfigurationInstance(configurationParameters.type)
        config.enabled = configurationParameters.enabled
        config.name = configurationParameters.name

        Calendar today = Calendar.getInstance();
        today.clear(Calendar.HOUR); today.clear(Calendar.MINUTE); today.clear(Calendar.SECOND);
        Date todayDate = today.getTime();

        taskScheduler.scheduleTask(config, taskScheduler.scheduleFactory.cron(todayDate, configurationParameters.cron))
    } catch (e) {
        log.info("An error occurred while creating the task " + configurationParameters.name + ". It might already exists, skipping...")
        return e
    }
}

createCompactBlobstoreTask()