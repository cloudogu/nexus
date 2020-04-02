# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [unreleased]

### Added

A new CES registry key `logging/root` is evaluated to override the default root log level. One of these values can be set in order to increase the log verbosity: `ERROR`, `WARN`, `INFO`, `DEBUG`.

### Fixed

Reduce the default root log level to WARN. Nexus's defaults to INFO which leads to an obscene amount of log entries from the underlying Felix framework.  

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

