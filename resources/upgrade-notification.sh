#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

FROM_VERSION="${1}"
TO_VERSION="${2}"

if [[ $FROM_VERSION == 2* ]] && [[ $TO_VERSION == 3* ]]; then
    YELLOW='\033[1;33m'
    NC='\033[0m'
    printf "${YELLOW}~~~~Information~~~~\n"
    printf "${NC}During the upgrade to Nexus 3, your Nexus 2 data will be backed up to /var/lib/ces/nexus/volumes/migration.\n"
    printf "\nTo migrate your data, please follow this instruction after upgrading to Nexus 3:
    1. Install Nexus 2 via docker locally (see https://hub.docker.com/r/sonatype/nexus/)
    2. Start your local Nexus 2 and create the repositories you wish to migrate via the UI
    3. Stop your local Nexus 2 and copy the storage content from the Nexus 2 backup volume to your local Nexus 2 volume
       (for example from /var/lib/ces/nexus/volumes/migration/storage/ to /var/lib/docker/volumes/nexus/_data/storage/).
    4. Start your local Nexus 2 and check if all repositories were imported correctly. If access errors occur, check for correct owner and group of migrated files.

    Afterwards please follow the official migration steps for Nexus 3
    (https://help.sonatype.com/repomanager3/upgrading/upgrade-procedures) and keep in mind:
    - Agent Connection step: The base URL of the remote server is the URL of your local Nexus 2 created in step 1 above
    - Content step: DO NOT check the \"server configuration\" option!\n"

    printf "\nFeel free to contact hello@cloudogu.com for questions\n"
fi