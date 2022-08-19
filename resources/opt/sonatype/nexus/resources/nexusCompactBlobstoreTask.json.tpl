{
  "type":   "blobstore.compact",
  "enabled":  "{{ .Config.GetOrDefault "compact_blobstore_task/enabled" "true"}}",
  "blobstore":  "{{ .Config.GetOrDefault "compact_blobstore_task/blobstore" "default"}}" ,
  "name": "default CES compact blobstore task" ,
  "cron": "{{ .Config.GetOrDefault "compact_blobstore_task/cron"  "0 0 3 * * ?"}}"
}