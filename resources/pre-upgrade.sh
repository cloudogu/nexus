#!/bin/bash


set -o errexit
set -o nounset
set -o pipefail

export MIGRATION_FROM_2_TO_3=false;
NEXUS_DATA_DIR=/var/lib/nexus

FROM_VERSION="${1}"
TO_VERSION="${2}"

if [[ $FROM_VERSION == 2* ]] && [[ $TO_VERSION == 3* ]]; then
    touch "${NEXUS_DATA_DIR}"/dataForMigration
fi