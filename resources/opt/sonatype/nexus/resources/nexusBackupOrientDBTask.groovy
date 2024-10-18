import org.sonatype.nexus.scheduling.TaskConfiguration
import org.sonatype.nexus.scheduling.TaskSupport

def createBackupOrientDBTask() {
    def taskScheduler = container.lookup(TaskScheduler.class.getName())

    def existingTasks = taskScheduler.listsTasks().findAll { it.getTypeId() == configurationParameters.type && it.getName() == configurationParameters.name }
    existingTasks.collect { it.remove() }

    TaskConfiguration config = taskScheduler.createTaskConfigurationInstance("db.backup")
    config.setEnabled(true)
    config.setName("DatabaseBackup")
    config.setString("location", "var/lib/nexus")

    TaskSupport task = new TaskSupport(true)
    task.configure(config)
    task.call()
}

createBackupOrientDBTask()