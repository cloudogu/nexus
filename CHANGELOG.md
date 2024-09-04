# Nexus Repository OSS Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v3.68.1-5] - 2024-09-04
### Changed
- [#137] update nexus-carp version to v1.4.0
    - This adds the ability to bypass CAS-authentication for direct service-account-requests to nexus. Which prevents request-throttling in CAS for requests that only have dogu-internal authentication.

## [v3.68.1-4] - 2024-08-07
### Changed
- [#135] update base image to OpenJDK 11.0.24-1
- update Alpine to 3.20.2-1

### Security
- [#135] close CVE-2024-41110

## [v3.68.1-3] - 2024-07-31
### Changed
- [#133] Create volume for local config

## [v3.68.1-2] - 2024-07-01
### Changed
- [#131] Update base image to java:11.0.23-3 to use doguctl v0.12.0

## [v3.68.1-1] - 2024-05-17
### Changed
- [#128] Upgrade nexus to 3.68.1 to fix CVE-2024-4956

### Fixed
- [#126] Align Cypress versions of Jenkinsfile and package.json to avoid failing integration tests

## [v3.59.0-2] - 2023-10-23
### Fixed
- [#124] Fixed CVE-2023-38039 CVE-2023-38545 CVE-2023-44487

## [v3.59.0-1] - 2023-08-18
### Changed
- [#120] Fix integration tests after CAS-Upgrade
- [#122] Upgrade Sonatype Nexus to 3.59.0-01

## [v3.52.0-2] - 2023-06-27
### Added
- [#118] Configuration options for resource requirements
- [#118] Defaults for CPU and memory requests

## [v3.52.0-1] - 2023-04-21
### Changed
- [#116] Upgrade Sonatype Nexus to 3.52.0-01
- [#116] Upgrade Shiro to v1.11.0
- [#116] Upgrade Base Image to 8u362-1

### Security
- [#116] Fixed
  - CVE-2015-7501
  - CVE-2020-11989
  - CVE-2020-1957
  - CVE-2021-41303
  - CVE-2022-32532
  - CVE-2022-32532
  - CVE-2015-3253
  - CVE-2017-1000487
  - CVE-2022-32532
  - CVE-2022-40664
  - CVE-2022-40664
  - CVE-2022-32221
  - CVE-2022-42915
  - CVE-2022-32221
  - CVE-2022-42915
  - CVE-2022-40664
  - CVE-2021-46848
  - CVE-2022-36437
  - CVE-2023-23914
  - CVE-2023-23914
  - CVE-2023-27536
  - CVE-2023-27536

## [v3.40.1-2] - 2022-08-19
### Added
- Preconfigured compact blobstore task which will run every 14 days. #108
- Preconfigured cleanup policy which, wenn added to a matching maven-snapshot repository, will mark artifacts older than 14 days for deletion. #108
### Fixed
- Remove orientDB credentials from log messages. #88

## [v3.40.1-1] - 2022-07-12
### Changed
- Upgrade Sonatype Nexus to v3.40.1-01; #106
- Upgrade Makefiles to 6.0.3
- Upgrade Base Image to 8u302-3

## [v3.37.3-4] - 2022-04-06
### Changed
- Upgrade zlib package to fix CVE-2018-25032; #100

## [v3.37.3-3] - 2022-03-09
### Fixed
- Logging: nexus-carp glog logger now logs to stderr; #97

## [v3.37.3-2] - 2022-02-07
### Changed
- Upgrade to OpenJDK 8u302

## [v3.37.3-1] - 2022-01-13
### Changed
- Upgrade to Nexus 3.37.3; #92

## [v3.34.1-4] - 2021-12-13
### Fixed
- Disable jndi lookup due to a vulnerability #90 (https://doc.nexusgroup.com/pages/viewpage.action?pageId=83133294)

## [v3.34.1-3] - 2021-11-02
### Changed
- Updated cypress to version 8.6.0
- Updated dogu-integration-test-library to version 1.0.0

### Fixed
- Service accounts had no support for redeployment of repositories. Now, every repository created with a service account allows redeploy.

## [v3.34.1-2] - 2021-10-18
### Added
- Support for service accounts. For more information see [docs](docs/operations/Configure_Service_Accounts_en.md)

## [v3.34.1-1] - 2021-09-28
### Changed
- Upgrade to Nexus 3.34.1; #83
- Upgrade to java 8u282

## [v3.32.0-2] - 2021-09-08
### Fixed
- Login workflow with CAS 6 in combination with OIDC.
  - When a user logs in via OIDC, a separate, unique user ID is transmitted by the OIDC provider.
    This user ID is now used as username (and at the same time as a unique ID). This User ID is 
    displayed in Nexus in the 'Username' fields; #80

## [v3.32.0-1] - 2021-08-12
### Changed
- Update nexus to version 3.32.0 (#77)

## [v3.30.1-2] - 2021-06-08
### Fixed
- Fixed restart loop when `config/nexus/claim/always` key is set (#75)

## [v3.30.1-1] - 2021-05-26
### Changed
- Upgrade to Sonatype Nexus 3.30.1; #73

## [v3.30.0-2] - 2021-05-05
### Changed
- Create temporary admin at each start (#71)

## [v3.30.0-1] - 2021-04-01
### Changed
- Upgrade to Sonatype Nexus 3.30.0; #68

## [v3.28.1-4] - 2021-03-22
### Changed
- Update dogu-build-lib to `v1.1.1`
- Update zalenium-build-lib to `v2.1.1`
- Toggle video recording with build parameter (#63)

### Removed
- Installation of R and Helm plugins. These plugins are a built-in feature now. (#66)

## [v3.28.1-3] - 2020-12-14
### Added
- Ability to configure the `MaxRamPercentage` and `MinRamPercentage` for the Nexus process inside the container via `cesapp edit-conf`  (#61)

## [v3.28.1-2] - 2020-11-27
### Fixed
- Remove nexus admin password from environment variable. Now, the password is passed via enviroment variable passing only to the respective tools (#59)

## [v3.28.1-1] - 2020-11-16
### Changed
- Upgrade Nexus to 3.28.1; #57
- Upgrade to java base image 8u252-1

## [v3.27.0-2] - 2020-09-22
### Added
- Added Permission `nx-repository-view---read` to cesUser #55. This will not affect existing nexus installations.

## [v3.27.0-1] - 2020-09-14
### Changed
- Upgrade Nexus to 3.27.0; #53
- Upgrade java base image to 8u242-3
- Upgrade R Plugin to 1.1.20
- Upgrade Helm plugin to 1.0.20
- Upgrade tini to 0.19.0

## [v3.23.0-6] - 2020-09-10
### Changed
- Don't fail to start the dogu if any of the Nexus health checks fails; #51
   - less than 4 processors do no longer raise an error and will not lead to a Nexus reboot
   - as [Nexus still requires 4 processors](https://issues.sonatype.org/browse/NEXUS-19839) a warning will be logged instead
- Provide information about failed Nexus health checks in log file, if any

## [v3.23.0-5] - 2020-09-04
### Added
- Add `base-url` and `resource-path` configuration for carp

### Changed
- Upgrade nexus-carp to v1.1.0; #47

## [v3.23.0-4] - 2020-09-04
### Changed
- Register missing appenders in logging configuration 

## [v3.23.0-3] - 2020-07-24
### Changed
- Update dogu-build-lib
- Update ces-build-lib
- Update java image
- Use doguctl validation

## [v3.23.0-2] - 2020-07-02
### Changed
- Update carp.yml.tpl to contain log-level and log-format
- Update nexus-carp to v1.0.0

## [v3.23.0-1] - 2020-06-18
### Changed
- Updated Nexus version to 3.23.0
- Enabled groovy scripting during startup in `nexus.properties`
- Update nexus-claim to v1.0.0

## [3.19.1-2] - 2020-04-15
### Added
- A new CES registry key `logging/root` is evaluated to override the default root log level. One of these values can be set in order to increase the log verbosity: `ERROR`, `WARN`, `INFO`, `DEBUG`. These log levels are directly applied to Nexus's logback root appender configuration.
  Changing Nexus's log level with different settings at runtime is still supported. Please note that these settings are reset (to the root log level from above) during a restart of the Nexus dogu. (#37)

### Changed
- In order to cope with the amount of file system data the max history is set to 7 days worth of Nexus logging, capping the total log size to 10 MBytes. This is only important for Nexus's own Log viewer. Logs to the Cloudogu EcoSystem host are not subject to change though. (#37)

## Removed
- Remove unnecessary log appenders (#37).

### Fixed
- Reduce the default root log level to WARN. Nexus's defaults to INFO which leads to an obscene amount of log entries from the underlying Felix framework. (#37)

## [3.19.1-1] - 2019-12-09
### Changed
- Changed Nexus version from 3.18.1 to 3.19.1
- Changed Java version in Dockerfile to 8u222-1

### Added
- Added docker health check
- Add a start-up check whether the minimum number of CPU cores is reached (#36)
   - Starting with [Nexus Repository Manager 3.17](https://issues.sonatype.org/secure/ReleaseNote.jspa?projectId=10001&version=17890) a minimum number of 4 CPU cores is enforced, otherwise the Repository Manager is no longer guaranteed to work.
   - The added check adds a new healthy state during the Dogu start-up in order to provide a better visibility of the originating problem.
   - You can check for the health with the CES command `cesapp healthy nexus`
