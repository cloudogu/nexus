#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC1091
source /hooks/sa-hook-common.sh

# create-sa.sh only understands these two parameters
readKnownParams "fullAccessRepository permissions" "$@"

# call create-sa.sh
exec /hooks/create-sa.sh "${PLAIN_PARAMS[@]}" "${CONSUMER}"
