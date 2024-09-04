## Service accounts

Nexus service accounts are created or deleted using the Exposed Commands `service-account-create` and `service-account-remove`.
When creating, the name of the service account is generated according to a predefined scheme.

This naming scheme is also specified as a regex in the Nexus-CARP configuration in order to bypass CAS authentication for service account requests.
If the naming scheme is changed, the configuration `service-account-name-regex` in the [`carp.yaml.tpl`](../../resources/etc/carp/carp.yml.tpl) must be adjusted accordingly. <!-- markdown-link-check-disable-line -->
