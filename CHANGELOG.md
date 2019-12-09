# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Changed version from 3.18.1 to 3.19.1
- Changed java version in Dockerfile to 8u222-1

### Added
- Added docker health check
- Add a start-up check whether the minimum number of CPU cores is reached (#36)
   - Starting with [Nexus Repository Manager 3.17](https://issues.sonatype.org/secure/ReleaseNote.jspa?projectId=10001&version=17890) a minimum number of 4 CPU cores is enforced, otherwise the Repository Manager is no longer guaranteed to work.
   - The added check adds a new healthy state during the Dogu start-up in order to provide a better visibility of the originating problem.
   - You can check for the health with the CES command `cesapp healthy nexus`

