import org.sonatype.nexus.scheduling.internal.TaskFactoryImpl
import org.sonatype.nexus.scheduling.TaskScheduler
import org.sonatype.nexus.scheduling.TaskConfiguration

//TODO configure necceasry fields
def createTask() {

    def taskScheduler = container.lookup(TaskScheduler.class.getName())

    TaskConfiguration config = taskScheduler.createTaskConfigurationInstance("blobstore.compact")
    config.enabled = true
    config.name = "compactBlobstoreTask"
    // task.properties?.each { key, value -> config.setString(key, value) }
    Calendar today = Calendar.getInstance();
    today.clear(Calendar.HOUR); today.clear(Calendar.MINUTE); today.clear(Calendar.SECOND);
    Date todayDate = today.getTime();

    taskScheduler.scheduleTask(config, taskScheduler.scheduleFactory.cron(todayDate, "0 0 0 1,15 * ?"))
}

createTask()