import org.sonatype.nexus.scheduling.TaskConfiguration;
import org.sonatype.nexus.scheduling.TaskScheduler;

def taskScheduler = container.lookup(TaskScheduler.class.getName());
TaskConfiguration config = taskScheduler.createTaskConfigurationInstance("db.backup");
config.setEnabled(true);
config.setName("h2DatabaseBackup");
config.setString("location", "/opt/sonatype/nexus");
taskScheduler.submit(config);