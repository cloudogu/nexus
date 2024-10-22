import org.sonatype.nexus.scheduling.TaskConfiguration
import org.sonatype.nexus.scheduling.TaskScheduler

def createBackupOrientDBTask() {
    def taskScheduler = container.lookup(TaskScheduler.class.getName())

    TaskConfiguration config = taskScheduler.createTaskConfigurationInstance("db.backup")
    config.setEnabled(true)
    config.setName("backupOrientDatabase")
    config.setString("location", "/var/lib/nexus")

    taskScheduler.submit(config)
}

createBackupOrientDBTask()