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

versionXEarlierEQY() {
    printf '%s\n' "$1" "$2" | sort -c -V
}

versionXLaterEQY() {
  versionXEarlierEQY "$2" "$1"
}

echo "${FROM_VERSION}" "${TO_VERSION}"
if [[ "${FROM_VERSION}" == 3.70.2* ]] && [[ "${TO_VERSION}" == 3.75.0* ]]; then
    printf "~~~~Warning~~~~\n"
    printf "Going from Nexus 3.70.2 to 3.75.0 requires a migration of the existing OrientDB to a H2 database\n"
    printf "This migration will be performed automatically by the upgrade script\n"
    printf "It is not necessary to perform a manual backup of the database, all Nexus data will be transfered to the new database\n"
    printf "\nFor additional support or questions, feel free to contact hello@cloudogu.com.\n"
fi

if versionXEarlierEQY "${FROM_VERSION}" "3.68.1-6" && versionXLaterEQY "${TO_VERSION}" "3.75.0-1"; then
    printf "~~~~Warning~~~~\n"
    printf "This update requires a database migration!\n"
    printf "Migration options:"
    printf "1) 3.70.2 -> 3.75.0: migrates Nexus from an OrientDB to an H2 database."
    printf "2) 3.70.2 -> 3.82.0: migrates Nexus from an OrientDB to a postgresql database."
    printf "3) 3.70.2 -> 3.75.0 -> 3.82.0: migrates Nexus from an OrientDB to a postgresql database."
    printf "The upgrade process will exit now\n"
    printf "\nFor additional support or questions, feel free to contact hello@cloudogu.com.\n"
    exit 2
fi

if [[ "${FROM_VERSION}" == 3.70.2* ]] && [[ "${TO_VERSION}" == 3.82.0* ]]; then
    printf "~~~~Warning~~~~\n"
    printf "Going from Nexus 3.70.2 to 3.82.0 requires a migration of the existing OrientDB to a postgresql database\n"
    printf "This migration will be performed automatically by the upgrade script\n"
    printf "It is not necessary to perform a manual backup of the database, all Nexus data will be transfered to the new database\n"
    printf "\nFor additional support or questions, feel free to contact hello@cloudogu.com.\n"
fi
