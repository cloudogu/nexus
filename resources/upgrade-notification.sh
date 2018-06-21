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
    printf "${NC}Before upgrading to nexus 3, we will back up your data at /var/lib/NexusBackup. Please follow our instruction if you wish to import your nexus 2 data to your upgraded nexus 3 \n"
fi