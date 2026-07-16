#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC1091
source /hooks/sa-hook-common.sh

# remove-sa.sh only understands this one optional parameter (deletion of the granted repository).
readKnownParams "fullAccessRepository" "$@"

# call remove-sa.sh
exec /hooks/remove-sa.sh "${PLAIN_PARAMS[@]}" "${CONSUMER}"
