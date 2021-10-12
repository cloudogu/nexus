#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

source nexus_api.sh
source util.sh

REPO_TO_BE_DELETED=""
NUMBER_OF_PARAMS=$#

if [ "${NUMBER_OF_PARAMS}" -le 0 ]; then
  echo "usage remove-sa.sh [optional parameters] <service name>"
  exit 1
fi

# Get the latest parameter as service name
SERVICE="${!NUMBER_OF_PARAMS}"
echo "Create service account for service: ${SERVICE}"
let NUMBER_OF_PARAMS--

# Look for optional parameters
i="${NUMBER_OF_PARAMS}"
while [ $i -ge 1 ]; do
  params="${!i}"

  if [ "$(echo "${params}" | sed 's/=.*//g')" == "fullAccessRepository" ]; then
    REPO_TO_BE_DELETED="$(echo "${params}" | sed 's/fullAccessRepository=//g')"
    echo "Request deletion of repository ${REPO_TO_BE_DELETED}..."
  fi

  let i--
done

# admin credentials
ADMIN_USER="$(doguctl config -e admin_user)"
ADMIN_PASSWORD="$(doguctl config -e admin_pw)"

# remove service user
echo "Remove service account for ${SERVICE}..."
RESPONSE="$(sql "SELECT id FROM user WHERE (id LIKE 'service_account_${SERVICE}_%')")" >/dev/null 2>&1
USER_ID=$(echo "${RESPONSE}" | grep '|' | grep "${SERVICE}" | sed 's/|//g' | sed 's/[0-9]*\s*//') || true
echo "Found the following users for the service ${SERVICE}: ${USER_ID}"

IFS=$'\n' a=(${USER_ID})
for i in "${!a[@]}"; do
  USER="${a[i]}"
  echo "\Deleting user ${USER}..."
  deleteUserViaAPI "${ADMIN_USER}" "${ADMIN_PASSWORD}" ${USER} || true
done

echo "Deleting service role service_account_role_${SERVICE}..."
deleteRoleForServiceViaAPI "${ADMIN_USER}" "${ADMIN_PASSWORD}" "service_account_role_${SERVICE}" || true

if [ ! -z "${REPO_TO_BE_DELETED}" ]; then
  echo "Deleting repository ${REPO_TO_BE_DELETED}..."
  deleteRepositoryViaAPI "${ADMIN_USER}" "${ADMIN_PASSWORD}" ${REPO_TO_BE_DELETED} || true
fi
