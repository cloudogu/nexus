# Vorkonfigurierte Nexus Settings
Durch die verwendung von Scripten die zum start des Nexus aufgerufen werden eine *Cleanup Policy* sowie ein *Compact Blobstore Task* angelegt.

## Compact Blobstore Task
Wird in Nexus ein Artefakt zum Löschen vorgesehen (bspw. durch den automatisch laufenden *Cleanup Service Task*) wird das
Artefakt nur zum Löschen markiert. Das endgültige Löschen der Daten aus dem Blobstore übernimmt ein *Compact Blobstore Task,* 
welcher aber nicht in der standardkonfiguration von Nexus konfiguriert ist.
Dieser Task wird beim Start der Applikation von dem Skript `nexusSetupCompactBlobstoreTask.groovy` angelegt.
Der Task löscht hierbei Daten (täglich, wenn die standard Konfiguration verwendet wird) aus dem _default_ Blobstore. Falls ein anderer Blobstore konfiguriert werden soll, kann hierfür 
der etcd-Schlüssel `config/nexus/compact_blobstore_task/blobstore` angepasst werden. 
Dies geht am einfachsten über den cesapp Befehl  `cesapp edit-config nexus`.

## Cleanup Policy
Wie auch der oben genannte Task wird eine Policy (`ces-maven-snapshot-cleanuppolicy`) per Skript (`nexusSetupCleanupPolicies.groovy`)
angelegt. Diese Cleanup Policy ist für maven-snapshot Repositorys gedacht. Um sie anzuwenden, muss entweder das Repository manuell konfiguriert werden oder
in einer hcl Konfiguration per `nexus-claim` das Feld `policyName` mit einer Liste aus Policies gefüllt werden die `ces-maven-snapshot-cleanuppolicy` enthält.

```
repository "public" {
  _state = "present"
  online = true
  recipeName = "maven2-hosted"
  attributes = {
    cleanup = {
      policyName = ["ces-maven-snapshot-cleanuppolicy"]
    },
    
    ...
  }
```

Die Policy kann in per `cesapp edit-config nexus` konfiguriert werden. Das Standardintervall für die Policy beträgt 14 Tage.


