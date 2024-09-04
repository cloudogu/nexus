## Service-Accounts

Nexus-Service-Accounts werden durch die Exposed Commands `service-account-create` und `service-account-remove` erstellt bzw. wieder gelöscht.
Beim Erstellen wird der Name des Service-Accounts nach einem vorgegebenen Schema generiert. 

In der Konfiguration des Nexus-CARP ist ebenfalls dieses Namensschema als Regex angegeben, um die CAS-Authentifizierung für Service-Account-Requests zu umgehen.
Wenn das Namensschema geändert wird, muss die Konfiguration `service-account-name-regex` in der [`carp.yaml.tpl`](../../resources/etc/carp/carp.yml.tpl) entsprechend angepasst werden.