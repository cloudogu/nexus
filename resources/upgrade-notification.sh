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
    printf "${NC}Before upgrading to Nexus 3, your data will be backed up to /var/lib/ces/nexus/volumes/migration.\n"
    printf "\nTo migrate your data, please follow this instruction first BEFORE upgrading:
    1. Install Nexus 2 via docker locally
    2. Start your local Nexus 2 and create with the UI the repositories you wish to migrate
    3. Copy the content from the Nexus 2 backup repository to your local Nexus 2 repository
       (for example from /var/lib/ces/nexus/volumes/migration/xxx to /var/lib/docker/volumes/nexus/_data/storage/xxx)

    Afterwards please follow these steps to upgrade and migrate:
    1. Upgrade Nexus 2 to Nexus 3
    2. Follow the official migration steps for Nexus 3 in the link below. DO NOT check the \"server configuration\" checkbox at the step \"Content\"
       https://help.sonatype.com/repomanager3/upgrading/upgrade-procedures\n"

    printf "\nFeel free to contact hello@cloudogu.com for questions\n"
fi