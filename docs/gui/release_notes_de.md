# Release Notes

Im Folgenden finden Sie die Release Notes für das Sonatype Nexus-Dogu. 

Technische Details zu einem Release finden Sie im zugehörigen [Changelog](https://docs.cloudogu.com/de/docs/dogus/nexus/CHANGELOG/).

## [Unreleased]
* Fehler in "claim/once" für CES Multinode behoben
    * Wenn `claim/once.timestamp` auf einen aktuellen Zeitstempel gesetzt wird, wird das "claim/once"-Skript ausgeführt.
      Der Zeitstempel muss im Format `YYYY-MM-DD hh:mm:ss` sein (z.B. `2025-03-20 09:30:00`).
      Vor der Ausführung wird dieser Zeitstempel mit dem Zeitstempel der letzten Ausführung des "claim/once"-Skripts verglichen.
      Ist der hier eingegebene Zeitstempel „neuer“, wird das Skript ausgeführt.
    * `claim/once.lock` wird nicht mehr unterstützt. Verwenden Sie stattdessen `claim/once.timestamp`.

Übersetzt mit DeepL.com (kostenlose Version)

## [v3.75.0-3] - 2025-02-13
Wir haben nur technische Änderungen vorgenommen. Näheres finden Sie in den Changelogs.

## [v3.75.0-2] - 2025-01-27
Wir haben nur technische Änderungen vorgenommen. Näheres finden Sie in den Changelogs.

## [v3.75.0-1] - 2024-12-19
* Update der Nexus Version auf 3.75.0-6
* Nexus nutzt ab dieser Version eine H2-Datenbank statt der bisherigen OrientDB
    * Beim Upgrade von 3.70.2-x wird die Datenbank automatisch migriert
    * Es ist **nicht** möglich von einer pre-3.70.2-x-Version auf diese Version upzugraden. In diesem Fall muss erst auf die aktuellste 3.70.2-Version geupgraded werden.
    * In airgapped-Systemen muss zuerst die Version 3.70.2-5 installiert werden, da sich die benötigte Migrations-Jar in dieser Version befindet
    * Achtung: Die Migration benötigt mindestens 16GB Arbeitsspeicher

## 3.70.2-5
Wir haben nur technische Änderungen vorgenommen. Näheres finden Sie in den Changelogs.

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