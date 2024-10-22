import org.sonatype.nexus.scheduling.TaskConfiguration
import org.sonatype.nexus.scheduling.TaskSupport
// def taskScheduler = container.lookup(TaskScheduler.class.getName())
// def existingTasks = taskScheduler.listsTasks().findAll { it.getTypeId() == configurationParameters.type && it.getName() == configurationParameters.name }
// existingTasks.collect { it.remove() }
def config = taskScheduler.createTaskConfigurationInstance("db.backup")
config.setEnabled("enabled")
config.setName("testname1")
config.setString("location", "/var/lib/nexus")
def task = new TaskSupport(true)
task.configure(config)
task.call()