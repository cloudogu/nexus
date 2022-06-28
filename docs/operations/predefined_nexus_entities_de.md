# Vorkonfigurierte Nexus Settings
Durch die verwendung von Scripten die zum start des Nexus aufgerufen werden eine *Cleanup Policy* sowie ein *Compact Blobstore Task* angelegt.

## Compact Blobstore Task
Wird in Nexus ein Artefakt zum löschen vorgesehen (bspw. durch den automatisch laufenden *Cleanup Service Task*) wird das
Artefakt nur zum löschen markiert. Das endgültige Löschen der Daten aus dem Blobstore übernimmt ein *Compact Blobstore Task,* 
welcher aber nicht in der standardkonfiguration von Nexus konfiguriert ist.
Dieser Task wird beim start der Applikation von dem Skript `nexusSetupCompactBlobstoreTask.groovy` angelegt.
Der Task löscht aus dem default Blobstore. Falls ein anderer Blobstore konfiguriert werden soll kann hierfür 
die Datei `nexusCompactBlobstoreTask.json` angepasst werden. 

## Cleanup Policy
Wie auch der oben gennante Task wird eine Policy (`ces-maven-snapshot-cleanuppolicy`) per Skript (`nexusSetupCleanupPolicies.groovy`)
angelegt.Diese Cleanup Policy ist für maven-snapshot Repositorys gedacht. Um sie anzuwenden, muss entweder das Repository manuell konfiguriert werden oder
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

Die Policy kann in der Datei `nexusCleanupPolicies.json` konfiguriert werden.


