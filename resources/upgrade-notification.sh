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
    printf "${NC}Before upgrading to nexus 3, we will back up your data at /var/lib/ces/nexus/volumes/migration so you can migrate your nexus 2 datas to your new upgraded nexus 3.\n"
    printf "\nTo migrate your datas, please follow this instruction first BEFORE upgrading:
    1. Install nexus 2 via docker locally
    2. Start your local nexus 2 and create with the UI the repositories you wish to migrate
    3. Copy the content from the nexus 2 back-up repository to your local nexus 2 repository
       (for example from /var/lib/ces/nexus/volumes/migration/xxx to /var/lib/docker/volumes/nexus/_data/storage/xxx)

    After that please take these steps to upgrade and migrate:
    1. Upgrade nexus 2 to nexus 3
    2. Follow the official migration steps for nexus 3 in the link below. DO NOT check the \"server configuration\" checkbox at the step \"Content\"
       https://help.sonatype.com/repomanager3/upgrading/upgrade-procedures\n"

    printf "\nPlease contact hello@cloudogu.com for question\n"
fi