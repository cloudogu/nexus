#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

FROM_VERSION="${1}"
TO_VERSION="${2}"

if [[ "${FROM_VERSION}" == 2* ]] && [[ "${TO_VERSION}" == 3* ]]; then
    RED='\033[1;31m'
    NC='\033[0m'
    printf "%s~~~~Warning~~~~\n" "${RED}"
    printf "%sDuring the upgrade to Nexus 3, your Nexus 2 data will be backed up to /var/lib/ces/nexus/volumes/migration. Make sure to provide at least twice the amount of storage space your nexus is using right now!\n" "${NC}"
    printf "\nPlease backup your local Nexus users, because they will not get migrated to Nexus 3 and have to be recreated after the upgrade. This does not affect users from the user backend which are authenticated via CAS.\n"
    printf "\nTo migrate your data to Nexus 3, please follow these instructions after upgrading:
    1. Install Nexus 2 via docker locally (see https://hub.docker.com/r/sonatype/nexus/)
    2. Start your local Nexus 2 and create the repositories you wish to migrate via the UI
    3. Stop your local Nexus 2 and copy the storage content from the Nexus 2 backup volume to your local Nexus 2 volume
       (for example from /var/lib/ces/nexus/volumes/migration/storage/ to /var/lib/docker/volumes/nexus/_data/storage/).
    4. Start your local Nexus 2 and check if all repositories were imported correctly. If access errors occur, check for correct owner and group of migrated files.

    Afterwards please follow the official migration steps for Nexus 3
    (https://help.sonatype.com/repomanager3/upgrading/upgrade-procedures) and keep in mind:
    - Agent Connection step: The base URL of the remote server is the URL of your local Nexus 2 created in step 1 above.
    - Content step: DO NOT select the \"server configuration\" option!\n"

    printf "\nAfter you have finished the migration, please restart your nexus dogu and check the user privileges and roles in the Administration --> Security menu, as they have most likely changed.
Most notably, if you are using the CES user management, make sure that the admin group role (defined during CES setup) is granted the \"nx-all\" privilege!\n"

    printf "\nAfter a successful migration, remember to remove your old nexus 2 data from the /var/lib/ces/nexus/volumes/migration folder to recover the disc space it occupied.\n"

    printf "\nPlease be aware that the repository URLs have changed in Nexus 3. You might need to adapt your access routines.\n"

    printf "\nFor additional support or questions, feel free to contact hello@cloudogu.com.\n"
fi

MAJOR_VERSION_INDEX=1
MINOR_VERSION_INDEX=2
BUGFIX_VERSION_INDEX=3
DOGU_VERSION_INDEX=4

# Returns true if X is less than or equal to Y; otherwise false
function versionXLessOrEqualThanY() {
  local sourceVersion="${1}"
  local targetVersion="${2}"

  if [[ "${sourceVersion}" == "${targetVersion}" ]]; then
    return 0
  fi

  local sourceMajor=0 sourceMinor=0 sourceBugfix=0 sourceDogu=0 \
        targetMajor=0 targetMinor=0 targetBugfix=0 targetDogu=0 \
        majorLessOrEqual=0 minorLessOrEqual=0 bugfixLessOrEqual=0

  if ! is_valid_version "${sourceVersion}"; then
    echo "ERROR: source dogu version ${sourceVersion} does not seem to be a semantic version"
    exit 1
  fi

  if ! is_valid_version "${targetVersion}"; then
    echo "ERROR: target dogu version ${targetVersion} does not seem to be a semantic version"
    exit 1
  fi

  sourceMajor="$(get_version "${sourceVersion}" "${MAJOR_VERSION_INDEX}")"
  targetMajor="$(get_version "${targetVersion}" "${MAJOR_VERSION_INDEX}")"
  if [[ $((sourceMajor)) -lt $((targetMajor)) ]]; then
    return 0
  fi

  majorLessOrEqual="$(versionXLessOrEqualThanY "${sourceMajor}" "${targetMajor}")"
  sourceMinor="$(get_version "${sourceVersion}" "${MINOR_VERSION_INDEX}")"
  targetMinor="$(get_version "${targetVersion}" "${MINOR_VERSION_INDEX}")"
  if [[ $((sourceMinor)) -lt $((targetMinor)) ]] && [[ ! $majorLessOrEqual ]]; then
    return 0
  fi

  minorLessOrEqual="$(versionXLessOrEqualThanY "${sourceMinor}" "${targetMinor}")"
  sourceBugfix="$(get_version "${sourceVersion}" "${BUGFIX_VERSION_INDEX}")"
  targetBugfix="$(get_version "${targetVersion}" "${BUGFIX_VERSION_INDEX}")"
  if [[ $((sourceBugfix)) -lt $((targetBugfix)) ]] && [[ ! $majorLessOrEqual ]] && [[ ! $minorLessOrEqual ]]; then
    return 0
  fi

  bugfixLessOrEqual="$(versionXLessOrEqualThanY "${sourceBugfix}" "${targetBugfix}")"
  sourceDogu="$(get_version "${sourceVersion}" "${DOGU_VERSION_INDEX}")"
  targetDogu="$(get_version "${targetVersion}" "${DOGU_VERSION_INDEX}")"
  if [[ $((sourceDogu)) -lt $((targetDogu)) ]] && [[ ! $majorLessOrEqual ]] && [[ ! $minorLessOrEqual ]] && [[ ! $bugfixLessOrEqual ]]; then
    return 0
  fi

  return 1
}

# get_version returns the value of the given semver index. If the input is not a valid semantic version
# the function exits with exit code 1
# MAJOR_VERSION  -> 1
# MINOR_VERSION  -> 2
# BUGFIX_VERSION -> 3
# DOGU_VERSION   -> 4
get_version() {
  local version index value
  version="${1}"
  index="${2}"
  value="0"
  if ! is_valid_version "${version}"; then
    echo "ERROR: dogu version ${version} does not seem to be a semantic version"
    exit 1
  fi
  value=${BASH_REMATCH[index]}
  echo "${value}"
}

is_valid_version() {
  local version
  version="${1}"
  declare -r semVerRegex='([0-9]+)\.([0-9]+)\.([0-9]+)-([0-9]+)'
  if [[ ! ${version} =~ ${semVerRegex} ]]; then
    return 1
  fi
}

if [[ "${FROM_VERSION}" == 3.70.2* ]] && [[ "${TO_VERSION}" == 3.73.* ]]; then
    RED='\033[1;31m'
    printf "%s~~~~Warning~~~~\n" "${RED}"
    printf "%sGoing from Nexus 3.70.2 to 3.73.0 requires a migration of the existing OrientDB to a H2 database\n"
    printf "%sThis migration will be performed automatically by the upgrade script\n"
    printf "%sIt is not necessary to perform a manual backup of the database, all Nexus data will be transfered to the new database\n"
    printf "\nFor additional support or questions, feel free to contact hello@cloudogu.com.\n"
fi

if versionXLessOrEqualThanY "${FROM_VERSION}" "3.68.1-6" && ! versionXLessOrEqualThanY "${TO_VERSION}" "3.73.0-99"; then
    RED='\033[1;31m'
    printf "%s~~~~Warning~~~~\n" "${RED}"
    printf "%sThis update requires a database migration\n"
    printf "%sThe migration can only be performed when going from Nexus Version 3.70.2 to 3.73.0\n"
    printf "%sThe upgrade process will exit now\n"
    printf "\nFor additional support or questions, feel free to contact hello@cloudogu.com.\n"
    exit 2
fi