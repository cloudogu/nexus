#!/bin/bash


set -o errexit
set -o nounset
set -o pipefail


echo "pre-upgrade script is running"
#cp -r ${NEXUS_DATA_DIR} /var/lib/backupNexus

FROM_VERSION="${1}"
TO_VERSION="${2}"

if [[ $FROM_VERSION == 2* ]] && [[ $TO_VERSION == 3* ]]; then
    echo "setting flat"
    MIGRATION_FROM_2_TO_3=true
fi