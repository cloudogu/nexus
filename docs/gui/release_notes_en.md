# Release Notes

Below you will find the release notes for the Sonatype Nexus Dogu. 

Technical details on a release can be found in the corresponding [Changelog](https://docs.cloudogu.com/en/docs/dogus/nexus/CHANGELOG/).

## 3.75.0-1
* Update of the Nexus version to 3.75.0-6
* Nexus now uses an H2 database instead of an OrientDb
    * The database migration will be performed automatically when upgrading from 3.70.x
    * Es ist **nicht** möglich von einer pre-3.70.2-x-Version auf diese Version upzugraden. In diesem Fall muss erst auf die aktuellste 3.70.2-Version geupgraded werden.
    * It is **not** possible to upgrade from a pre-3.70.2-x version to this version. In this case update to the newest 3.70.2-x version first
    * For airgapped environments make sure to upgrade to 3.70.2-5 first, as this version contains the needed migration jar
    * Attention: The migration needs at least 16Gb of memory

## 3.70.2-4
We have only made technical changes. You can find more details in the changelogs.

## 3.70.2-3
We have only made technical changes. You can find more details in the changelogs.

## 3.70.2-2
We have only made technical changes. You can find more details in the changelogs.

## 3.70.2-1
* Update of the Nexus Version to 3.70.2-01
* Claim-Once can be reused after upgrading via blueprint

## 3.68.1-6
* The internal password generation has been secured by a new CARP version.
* Relicense own code to AGPL-3.0-only

## 3.68.1-5
* Fixes the problem that BasicAuth requests led to locks in the CAS.

## 3.68.1-4
* Fix of critical CVE-2024-41110 in library dependencies. This vulnerability could not be actively exploited, though.

## 3.68.1-3
We have only made technical changes. You can find more details in the changelogs.

## 3.68.1-2
We have only made technical changes. You can find more details in the changelogs.

## 3.68.1-1
**The release fixes critical security vulnerabilities ([CVE-2024-4956](https://github.com/advisories/GHSA-6cgv-69mq-8w7x)). An update is therefore recommended.**

* The Dogu now offers the Sonatype Nexus version 3.68.1. The release notes of Sonatype Nexus can be found [here](https://help.sonatype.com/en/sonatype-nexus-repository-3-68-0-release-notes.html).