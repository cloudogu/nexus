#!/bin/bash


set -o errexit
set -o nounset
set -o pipefail

NEXUS_DATA_DIR=/var/lib/nexus

FROM_VERSION="${1}"
TO_VERSION="${2}"

if [[ $FROM_VERSION == 2* ]] && [[ $TO_VERSION == 3* ]]; then
    touch "${NEXUS_DATA_DIR}"/migration
fi