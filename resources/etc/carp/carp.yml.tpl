---
cas-url: https://{{ .GlobalConfig.Get "fqdn" }}/cas
service-url: https://{{ .GlobalConfig.Get "fqdn" }}/nexus
target-url: http://localhost:8081
skip-ssl-verification: false
port: 8082
principal-header: X-CARP-Authentication
logout-method: DELETE
logout-path: /rapture/session
forwardUnauthenticatedRESTRequests: true
