#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# Rotates the password of an existing service account in place.
# The user, its ID, its role, the full access repository and everything else attached to the account are kept.

# Resolved relative to this script's own location (not hardcoded to /) so rotate-sa.sh/nexus_api.sh
# keep working no matter which directory they're both copied/mounted into together.
# shellcheck disable=SC1091
source "$(dirname "$0")/nexus_api.sh"

NUMBER_OF_PARAMS=$#
if [ "${NUMBER_OF_PARAMS}" -le 0 ]; then
  echo "usage rotate-sa.sh [optional parameters] <service name>" >&2
  exit 1
fi

# Get the latest parameter as service name
SERVICE="${!NUMBER_OF_PARAMS}"
echo "Rotate service account for service: ${SERVICE}" >&2
((NUMBER_OF_PARAMS--))

# Look for an optional "fullAccessRepository=<name>" parameter.
FULL_ACCESS_REPO_NAME=""
i="${NUMBER_OF_PARAMS}"
while [ "${i}" -ge 1 ]; do
  params="${!i}"
  if [ "${params//=*/}" == "fullAccessRepository" ]; then
    FULL_ACCESS_REPO_NAME="${params//fullAccessRepository=/}"
  fi
  ((i--))
done

# get username
USER_NAME=$(doguctl config service_accounts/"${SERVICE}" --default "default")
if [[ "${USER_NAME}" == "default" ]]; then
  echo "no service account registered for ${SERVICE} - nothing to rotate" >&2
  exit 1
fi

# create new random password
USER_PASSWORD=$(doguctl random)

# admin credentials
ADMIN_USER="$(doguctl config -e admin_user)"
ADMIN_PASSWORD="$(doguctl config -e admin_pw)"

HTTP_STATUS=$(changeUserPasswordViaAPI "${ADMIN_USER}" "${ADMIN_PASSWORD}" "${USER_NAME}" "${USER_PASSWORD}")
if [[ "${HTTP_STATUS}" != 2?? ]]; then
  echo "failed to change password of service account ${USER_NAME}: Nexus responded with HTTP ${HTTP_STATUS}" >&2
  exit 1
fi

if [ -n "${FULL_ACCESS_REPO_NAME}" ]; then
  echo "repository: ${FULL_ACCESS_REPO_NAME}"
fi
echo "username: ${USER_NAME}"
echo "password: ${USER_PASSWORD}"
