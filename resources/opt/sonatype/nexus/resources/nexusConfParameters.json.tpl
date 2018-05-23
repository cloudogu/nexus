{
  "fqdn": "{{ .GlobalConfig.Get "fqdn" }}",
  "defaultAdminPassword": "{{ .Env.Get "ADMINDEFAULTPASSWORD" }}",
  "newAdminPassword": "{{ .Env.Get "NEWADMINPASSWORD" }}",
  "adminGroup": "{{ .GlobalConfig.Get "admin_group" }}"
}
