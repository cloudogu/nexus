# Konfiguration von Service Accounts

Nexus bietet die Möglichkeit Service Accounts anzulegen. 

## Konfiguration

Dafür muss im Zieldogu ein Eintrag in dem `ServiceAccount` Abschnitt der `dogu.json` erfolgen:

```json
{
  "Type": "nexus",
  "Params": [
    "fullAccessRepository=myRepositoryData",
    "permissions=nx-repository-admin-maven2-maven-public-*,nx-repository-view-nuget-nuget-hosted-*"
  ]
}
```

Beide Parameter (`Params`) sind optional und haben folgende Funktion:

**fullAccessRepository** – Der zu erstellende Account hat vollen Zugriff auf ein neues angelegtes Repository im Nexus.
Der Name des Repositories wird zusammen mit dem Parameter in die `Params` geschrieben.
Aus der oben genannten Beispielkonfiguration mit `fullAccessRepository=myRepositoryData` wird ein Repository mit dem
Namen `myRepositoryData` angelegt.

**permissions** – definiert eine Menge an Nexus-Rechten, welche dem erstellenden Service Account gegeben werden.
Aus dem Beispiel oben `permissions=nx-repository-admin-maven2-maven-public-*,nx-repository-view-nuget-nuget-hosted-*`
wird dem Service Account die Nexus-Permission: `nx-repository-admin-maven2-maven-public-*` und `nx-repository-view-nuget-nuget-hosted-*` verliehen.

## Verwendung

Die Benutzerdaten des Service Accounts werden für das Dogu im Secret ``<dogu>-config`` verschlüsselt gespeichert.
Folgende Schlüssel werden angelegt:

**sa-nexus/username** – der Benutzername des Service Accounts. Dieser Schlüssel wird immer angelegt.

**sa-nexus/password** – das Passwort des Service Accounts. Dieser Schlüssel wird immer angelegt.

**sa-nexus/repository** – der Name des Repositories, welches durch den Parameter `fullAccessRepository=repoName` konfiguriert wurde. 
Dieser Schlüssel wird nur angelegt wenn der SA mit dem Parameter `fullAccessRepository` konfiguriert wurde.