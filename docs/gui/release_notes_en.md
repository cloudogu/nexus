# Release Notes

Below you will find the release notes for the Sonatype Nexus Dogu. 

Technical details on a release can be found in the corresponding [Changelog](https://docs.cloudogu.com/en/docs/dogus/nexus/CHANGELOG/).

## Release 3.68.1-6
* Safe password generation with `java.security.SecureRandom`.

## Release 3.68.1-5
* Fixes the problem that BasicAuth requests led to locks in the CAS.

## Release 3.68.1-4
* Fix of critical CVE-2024-41110 in library dependencies. This vulnerability could not be actively exploited, though.

## Release 3.68.1-3

We have only made technical changes. You can find more details in the changelogs.

## Release 3.68.1-2

We have only made technical changes. You can find more details in the changelogs.

## Release 3.68.1-1

**The release fixes critical security vulnerabilities ([CVE-2024-4956](https://github.com/advisories/GHSA-6cgv-69mq-8w7x)). An update is therefore recommended.**

* The Dogu now offers the Sonatype Nexus version 3.68.1. The release notes of Sonatype Nexus can be found [here](https://help.sonatype.com/en/sonatype-nexus-repository-3-68-0-release-notes.html).