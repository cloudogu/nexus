{
  "type":  "{{ .Config.GetOrDefault "compactBlobstoreTaskConfiguration/taskType" "blobstore.compact"}}",
  "enabled":  "{{ .Config.GetOrDefault "compactBlobstoreTaskConfiguration/enabled" "true"}}",
  "blobstore":  "{{ .Config.GetOrDefault "compactBlobstoreTaskConfiguration/blobstore" "default"}}" ,
  "name":  "{{ .Config.GetOrDefault "compactBlobstoreTaskConfiguration/taskName" "Compact blobstore"}}" ,
  "cron": "{{ .Config.GetOrDefault "compactBlobstoreTaskConfiguration/cron"  "0 0 0 1,15 * ?"}}"
}