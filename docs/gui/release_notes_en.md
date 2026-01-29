# Release Notes

Below you will find the release notes for the Sonatype Nexus Dogu. 

Technical details on a release can be found in the corresponding [Changelog](https://docs.cloudogu.com/en/docs/dogus/nexus/CHANGELOG/).

## [Unreleased]

### Security
- [#182] fixed [cve-2025-15467](https://avd.aquasec.com/nvd/2025/cve-2025-15467/)

## [v3.86.2-1] - 2025-12-15
### Changed
* Update of the Nexus version to 3.86.2-01

## [v3.82.0-3] - 2025-12-04
### Fixed
* Fixed migration from [`once.lock` to `once.timestamp`](#v3750-4---2025-03-27)
  * On migrations from Nexus v3.75.0-3 to higher versions, `claim/once` will now not be executed again
    if it had already been executed once.

## [v3.82.0-2] - 2025-09-19
### Added 
* Added new configuration key to make the amount of database connections nexus occupies configurable
  * database/maxConnections, default: 30

## [v3.82.0-1] - 2025-08-26
### Changed
* Update of the Nexus version to 3.82.0-08
  * Starting with this version, Nexus uses a postgresql database instead of the previous OrientDB/H2
  * When upgrading from 3.70.2-5 and 3.75.0-1, the database is automatically migrated
  * It is **not** possible to upgrade from a pre-3.70.2-x version to this version. In this case, you must first upgrade to the latest 3.70.2 version.
  * In airgapped systems, version 3.70.2-5/3.75.0-1 must be installed first, as the required migration jar is located in this version
  * Attention: The migration requires at least 16GB of RAM

## [v3.75.0-6] - 2025-06-27
### Added
- Adds a configuration option to provision data in repositories created by claims. See [docs](../operations/preconfigure_repository_data_en.md) for usage.

## [v3.75.0-5] - 2025-04-25
### Changed
- Usage of memory and CPU was optimized for the Kubernetes Mutlinode environment.

## [v3.75.0-4] - 2025-03-27
* Fix "claim/once" for CES Multinode
  * If `claim/once.timestamp` set to a current timestamp, it will execute the "claim/once"-script.
    The timestamp has to be in the format `YYYY-MM-DD hh:mm:ss` (e.g. `2025-03-20 09:30:00`).
    Before execution this timestamp is compared with the timestamp from the last execution of the "claim/once"-script.
    If the timestamp entered here is “newer”, the script will be executed.
  * `claim/once.lock` is no longer supported. Use `claim/once.timestamp` instead.

## [v3.75.0-3] - 2025-02-13
We have only made technical changes. You can find more details in the changelogs.

## [v3.75.0-2] - 2025-01-27
We have only made technical changes. You can find more details in the changelogs.

## [v3.75.0-1] - 2024-12-19
* Update of the Nexus version to 3.75.0-6
* Nexus now uses an H2 database instead of an OrientDb
    * The database migration will be performed automatically when upgrading from 3.70.x
    * It is **not** possible to upgrade from a pre-3.70.2-x version to this version. In this case update to the newest 3.70.2-x version first
    * For airgapped environments make sure to upgrade to 3.70.2-5 first, as this version contains the needed migration jar
    * Attention: The migration needs at least 16Gb of memory

## 3.70.2-5
We have only made technical changes. You can find more details in the changelogs.

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
