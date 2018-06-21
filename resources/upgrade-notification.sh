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
    printf "${NC}Before upgrading to nexus 3, we will back up your data at /var/lib/NexusBackup so you can migrate your nexus 2 datas to your new upgraded nexus 3.\nContact hello@cloudogu.com for question\n"
fi