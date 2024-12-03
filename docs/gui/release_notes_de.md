# Release Notes

Im Folgenden finden Sie die Release Notes für das Sonatype Nexus-Dogu. 

Technische Details zu einem Release finden Sie im zugehörigen [Changelog](https://docs.cloudogu.com/de/docs/dogus/nexus/CHANGELOG/).

## 3.73.0-1
* Update der Nexus Version auf 3.73.0-12
* Nexus nutzt ab dieser Version eine H2-Datenbank statt der bisherigen OrientDB
    * Beim Upgrade von 3.70.2-x wird die Datenbank automatisch migriert
    * Es ist **nicht** möglich von einer pre-3.70.2-x-Version auf diese Version upzugraden. In diesem Fall muss erst auf die aktuellste 3.70.2-Version geupgraded werden.

## 3.70.2-4
Wir haben nur technische Änderungen vorgenommen. Näheres finden Sie in den Changelogs.

## 3.70.2-3
Wir haben nur technische Änderungen vorgenommen. Näheres finden Sie in den Changelogs.

## 3.70.2-2
Wir haben nur technische Änderungen vorgenommen. Näheres finden Sie in den Changelogs.

## 3.70.2-1
* Update der Nexus Version auf 3.70.2-01
* Claim-Once kann nach Upgrade mittels Blueprint neu gesetzt werden

## 3.68.1-6
* Die interne Passwortgenerierung wurde durch eine neue CARP-Version abgesichert.
* Die Cloudogu-eigenen Quellen werden von der MIT-Lizenz auf die AGPL-3.0-only relizensiert.

## 3.68.1-5
* Behebung des Problems das BasicAuth-Requests zu Sperren im CAS geführt haben.

## 3.68.1-4
* Behebung von kritischem CVE-2024-41110 in Bibliotheksabhängigkeiten. Diese Schwachstelle konnte jedoch nicht aktiv ausgenutzt werden.

## 3.68.1-3
Wir haben nur technische Änderungen vorgenommen. Näheres finden Sie in den Changelogs.

## 3.68.1-2
Wir haben nur technische Änderungen vorgenommen. Näheres finden Sie in den Changelogs.

## 3.68.1-1
**Das Release behebt kritische Sicherheitslücken ([CVE-2024-4956](https://github.com/advisories/GHSA-6cgv-69mq-8w7x)). Ein Update ist daher empfohlen.**

* Das Dogu bietet nun die Sonatype Nexus-Version 3.68.1 an. Die Release Notes von Sonatype Nexus finden Sie [hier](https://help.sonatype.com/en/sonatype-nexus-repository-3-68-0-release-notes.html).