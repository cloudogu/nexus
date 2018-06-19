#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

FROM_VERSION="${1}"
TO_VERSION="${2}"

if [[ $FROM_VERSION == 2* ]] && [[ $TO_VERSION == 3* ]]; then
    YELLOW='\033[1;33m'
    NC='\033[0m'
    printf "${YELLOW}~~~~CAUTION~~~~\n"
    printf "${NC}Upgrading to nexus 3 now will delete every data from nexus 2. You won't be able to recreate them. Please ensure you have backed up your data.\n"
fi