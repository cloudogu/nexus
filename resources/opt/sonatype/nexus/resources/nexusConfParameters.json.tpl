{
  "fqdn": "{{ .GlobalConfig.Get "fqdn" }}",
  "defaultAdminPassword": "{{ .Env.Get "ADMINDEFAULTPASSWORD" }}",
  "newAdminPassword": "{{ .Env.Get "NEWADMINPASSWORD" }}",
  "adminGroup": "{{ .GlobalConfig.Get "admin_group" }}",
  {{ if .Config.Exists "proxyConfiguration/http/host" }}
  "proxyConfigurationHttpHost": "{{ .Config.Get "proxyConfiguration/http/host" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/http/port" }},
  "proxyConfigurationHttpPort": {{ .Config.Get "proxyConfiguration/http/port" }}{{ end }}{{ if .Config.Exists "proxyConfiguration/http/authentication/username" }},
  "proxyConfigurationHttpAuthenticationUsername": "{{ .Config.Get "proxyConfiguration/http/authentication/username" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/http/authentication/password" }},
  "proxyConfigurationHttpAuthenticationPassword": "{{ .Config.Get "proxyConfiguration/http/authentication/password" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/http/authentication/ntlmHost" }},
  "proxyConfigurationHttpAuthenticationNtlmHost": "{{ .Config.Get "proxyConfiguration/http/authentication/ntlmHost" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/http/authentication/domain" }},
  "proxyConfigurationHttpAuthenticationDomain": "{{ .Config.Get "proxyConfiguration/http/authentication/domain" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/https/host" }},
  "proxyConfigurationHttpsHost": "{{ .Config.Get "proxyConfiguration/https/host" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/https/port" }},
  "proxyConfigurationHttpsPort": {{ .Config.Get "proxyConfiguration/https/port" }}{{ end }}{{ if .Config.Exists "proxyConfiguration/https/authentication/username" }},
  "proxyConfigurationHttpsAuthenticationUsername": "{{ .Config.Get "proxyConfiguration/https/authentication/username" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/https/authentication/password" }},
  "proxyConfigurationHttpsAuthenticationPassword": "{{ .Config.Get "proxyConfiguration/https/authentication/password" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/https/authentication/ntlmHost" }},
  "proxyConfigurationHttpsAuthenticationNtlmHost": "{{ .Config.Get "proxyConfiguration/https/authentication/ntlmHost" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/https/authentication/domain" }},
  "proxyConfigurationHttpsAuthenticationDomain": "{{ .Config.Get "proxyConfiguration/https/authentication/domain" }}"{{ end }}{{ if .Config.Exists "proxyConfiguration/nonProxyHosts" }},
  "proxyConfigurationNonProxyHosts": "{{ .Config.Get "proxyConfiguration/nonProxyHosts" }}"
  {{ end }}
}
