import org.sonatype.nexus.scheduling.TaskConfiguration;
import org.sonatype.nexus.scheduling.TaskScheduler;

def taskScheduler = container.lookup(TaskScheduler.class.getName());
TaskConfiguration config = taskScheduler.createTaskConfigurationInstance("h2.backup.task");
config.setEnabled(true);
config.setName("h2DatabaseBackup");
config.setString("location", "/var/lib/nexus/db");
taskScheduler.submit(config);