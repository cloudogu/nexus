{
  "type":   "blobstore.compact",
  "enabled":  "{{ .Config.GetOrDefault "compact_blobstore_task/enabled" "true"}}",
  "blobstore":  "{{ .Config.GetOrDefault "compact_blobstore_task/blobstore" "default"}}" ,
  "name":  "{{ .Config.GetOrDefault "compact_blobstore_task/name" "Compact blobstore"}}" ,
  "cron": "{{ .Config.GetOrDefault "compact_blobstore_task/cron"  "0 3 * * *"}}"
}