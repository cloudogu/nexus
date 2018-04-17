{
  "fqdn": "{{ .GlobalConfig.Get "fqdn" }}",
  "defaultAdminPassword": "{{ .Env.Get "ADMINDEFAULTPASSWORD" }}",
  "newAdminPassword": "{{ .Env.Get "NEWADMINPASSWORD" }}"
}
