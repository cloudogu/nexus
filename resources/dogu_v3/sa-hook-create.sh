#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC1091
source /hooks/sa-hook-common.sh

# create-sa.sh only understands these two parameters
readKnownParams "fullAccessRepository permissions" "$@"

# Check if a password-rotation is needed
#
#   - no existing account                     -> create as usual
#   - existing account, rotation requested    -> remove the old account, then create a new one
#   - existing account, no rotation requested -> no-op

ROTATE="false"
for flag in "$@"; do
  if [[ "${flag}" == "--behavior-rotateServiceAccountNow=true" ]]; then
    ROTATE="true"
  fi
done

EXISTING_USER_ID=$(doguctl config service_accounts/"${CONSUMER}" --default "default")

if [[ "${EXISTING_USER_ID}" != "default" ]]; then
  if [[ "${ROTATE}" != "true" ]]; then
    echo "service account for ${CONSUMER} already exists (${EXISTING_USER_ID}), no rotation requested - leaving it as is" >&2
    exit 0
  fi

  # Rotating: remove the old account first.
  echo "rotating service account for ${CONSUMER} - removing existing account ${EXISTING_USER_ID} first" >&2
  /hooks/remove-sa.sh "${CONSUMER}" >&2
fi

# call create-sa.sh
exec /hooks/create-sa.sh "${PLAIN_PARAMS[@]}" "${CONSUMER}"
