import org.sonatype.nexus.scheduling.TaskConfiguration
import org.sonatype.nexus.scheduling.TaskSupport
import groovy.json.JsonSlurper


// get parameters from payload JSON file
def configurationParameters = new JsonSlurper().parseText(args)

def createBackupOrientDBTask(configurationParameters) {
    def taskScheduler = container.lookup(TaskScheduler.class.getName())
    def existingTasks = taskScheduler.listsTasks().findAll { it.getTypeId() == configurationParameters.type && it.getName() == configurationParameters.name }
    existingTasks.collect { it.remove() }

    TaskConfiguration config = taskScheduler.createTaskConfigurationInstance("db.backup")
    config.setEnabled("enabled")
    config.setName("testname1")
    config.setString("location", "/var/lib/nexus")

    Calendar today = Calendar.getInstance();
    today.clear(Calendar.HOUR); today.clear(Calendar.MINUTE); today.clear(Calendar.SECOND);
    Date todayDate = today.getTime();

    taskScheduler.scheduleTask(config, taskScheduler.scheduleFactory.cron(todayDate, configurationParameters.cron))
}

createBackupOrientDBTask(configurationParameters)