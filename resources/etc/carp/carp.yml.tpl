---
base-url: https://{{ .GlobalConfig.Get "fqdn" }}
cas-url: https://{{ .GlobalConfig.Get "fqdn" }}/cas
service-url: https://{{ .GlobalConfig.Get "fqdn" }}/nexus
target-url: http://localhost:8081
resource-path: /nexus/repository
skip-ssl-verification: false
port: 8082
principal-header: X-CARP-Authentication
logout-method: DELETE
logout-path: /rapture/session
forward-unauthenticated-rest-requests: true
log-format: "%{time:2006-01-02 15:04:05.000-0700} %{level:.4s} [%{module}:%{shortfile}] %{message}"
log-level: {{ .Config.GetOrDefault "logging/root" "WARN" }}
service-account-name-regex: "^service_account_([A-Za-z0-9]+)_([A-Za-z0-9]+)$"
limiter-token-rate: {{ .Config.GetOrDefault "carp-limiter/token-rate" "50" }}
limiter-burst-size: {{ .Config.GetOrDefault "carp-limiter/burst-size" "150" }}
limiter-clean-interval: {{ .Config.GetOrDefault "carp-limiter/clean-interval" "300" }}
