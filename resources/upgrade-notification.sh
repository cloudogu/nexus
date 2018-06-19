#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

FROM_VERSION="${1}"
TO_VERSION="${2}"

if [ "${FROM_VERSION}" == "2*" ] && "${TO_VERSION}" == "3*"; then
  echo "CAUTION! Upgrading to nexus 3 now will delete every datas from nexus 2. You won't be able to recreate them. Please ensure you have backed up your data."
fi