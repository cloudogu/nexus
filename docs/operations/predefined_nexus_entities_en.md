# Preconfigured Nexus settings
By using scripts that are called to start the Nexus, a *Cleanup Policy* and a *Compact Blobstore Task* are created.

## Compact Blobstore Task
If an artifact is scheduled for deletion in Nexus (e.g. by the automatically running *Cleanup Service Task*), the artifact is only **marked** for deletion but not actually deleted.
The final deletion of the data from the Blobstore is done by a *Compact Blobstore Task,*
which is not configured in the default Nexus configuration.
This task is created by the script `nexusSetupCompactBlobstoreTask.groovy` when the application is started.
The task deletes data daily (in its standard configuration) from the _default_ blobstore. If you want to configure a different blobstore, you can do this by 
modifying the etcd key `config/nexus/compact_blobstore_task/blobstore`.
The easiest way to do this is to use the cesapp command `cesapp edit-config nexus`.

## Cleanup Policy
Like the task mentioned above, a policy (`ces-maven-snapshot-cleanuppolicy`) is created by script (`nexusSetupCleanupPolicies.groovy`).
This cleanup policy is intended for maven-snapshot repositories. To apply it, either the repository has to be configured manually or
in a hcl configuration via `nexus-claim` the field `policyName` must be filled with a list of policies containing `ces-maven-snapshot-cleanuppolicy`.

```
repository "public" {
  _state = "present
  online = true
  recipeName = "maven2-hosted
  attributes = {
    cleanup = {
      policyName = ["ces-maven-snapshot-cleanuppolicy"]
    },
    
    ...
  }
```

The policy can be configured via `cesapp edit-config nexus` command. The default intervall for the cleanup policy is 14 days.