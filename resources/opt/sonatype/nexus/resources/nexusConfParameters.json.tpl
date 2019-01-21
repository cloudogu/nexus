{
  "fqdn": "{{ .GlobalConfig.Get "fqdn" }}",
  "defaultAdminPassword": "{{ .Env.Get "ADMINDEFAULTPASSWORD" }}",
  "newAdminPassword": "{{ .Env.Get "NEWADMINPASSWORD" }}",
  "adminGroup": "{{ .GlobalConfig.Get "admin_group" }}",
  {{ if .Config.Exists "proxyConfiguration/http/host" }}
  "proxyConfiguration/http/host": "{{ .Config.Get "proxyConfiguration/http/host" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/http/port" }},
  "proxyConfiguration/http/port": "{{ .Config.Get "proxyConfiguration/http/port" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/http/authentication/username" }},
  "proxyConfiguration/http/authentication/username": "{{ .Config.Get "proxyConfiguration/http/authentication/username" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/http/authentication/password" }},
  "proxyConfiguration/http/authentication/password": "{{ .Config.Get "proxyConfiguration/http/authentication/password" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/http/authentication/ntlmHost" }},
  "proxyConfiguration/http/authentication/ntlmHost": "{{ .Config.Get "proxyConfiguration/http/authentication/ntlmHost" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/http/authentication/domain" }},
  "proxyConfiguration/http/authentication/domain": "{{ .Config.Get "proxyConfiguration/http/authentication/domain" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/https/host" }},
  "proxyConfiguration/https/host": "{{ .Config.Get "proxyConfiguration/https/host" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/https/port" }},
  "proxyConfiguration/https/port": "{{ .Config.Get "proxyConfiguration/https/port" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/https/authentication/username" }},
  "proxyConfiguration/https/authentication/username": "{{ .Config.Get "proxyConfiguration/https/authentication/username" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/https/authentication/password" }},
  "proxyConfiguration/https/authentication/password": "{{ .Config.Get "proxyConfiguration/https/authentication/password" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/https/authentication/ntlmHost" }},
  "proxyConfiguration/https/authentication/ntlmHost": "{{ .Config.Get "proxyConfiguration/https/authentication/ntlmHost" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/https/authentication/domain" }},
  "proxyConfiguration/https/authentication/domain": "{{ .Config.Get "proxyConfiguration/https/authentication/domain" }}"
  {{ end }}
}
