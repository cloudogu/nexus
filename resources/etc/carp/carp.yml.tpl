---
cas-url: https://{{ .GlobalConfig.Get "fqdn" }}/cas
service-url: https://{{ .GlobalConfig.Get "fqdn" }}/nexus
target-url: http://localhost:8081
skip-ssl-verification: false
port: 8082
principal-header: X-CARP-Authentication
logout-method: DELETE
logout-path: /rapture/session
forward-unauthenticated-rest-requests: true
log-format: {{ .Config.GetOrDefault "logging/format" "\"%{time:2006-01-02 15:04:05.000-0700} %{level:.4s} [%{shortfile}] %{message}\"" }}
log-level: {{ .Config.GetOrDefault "logging/root" "DEBUG" }}
