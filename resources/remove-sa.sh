#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC1091
source /nexus_api.sh
# shellcheck disable=SC1091
source /util.sh

REPO_TO_BE_DELETED=""
NUMBER_OF_PARAMS=$#

if [ "${NUMBER_OF_PARAMS}" -le 0 ]; then
  echo "usage remove-sa.sh [optional parameters] <service name>"
  exit 1
fi

# Get the latest parameter as service name
SERVICE="${!NUMBER_OF_PARAMS}"
echo "Delete service account for service: ${SERVICE}"
((NUMBER_OF_PARAMS--))

# Look for optional parameters
i="${NUMBER_OF_PARAMS}"
while [ $i -ge 1 ]; do
  params="${!i}"

  if [ "${params//=*/}" == "fullAccessRepository" ]; then
    REPO_TO_BE_DELETED="${params//fullAccessRepository=/}"
    echo "Request deletion of repository ${REPO_TO_BE_DELETED}..."
  fi

  ((i--))
done

# admin credentials
ADMIN_USER="$(doguctl config -e admin_user)"
ADMIN_PASSWORD="$(doguctl config -e admin_pw)"

USER_ID=$(doguctl config service_accounts/"${SERVICE}" --default "default" || true)
if [[ "${USER_ID}" != "default" ]]; then
  {
    echo "Deleting service account ${USER_ID}..."
    deleteUserViaAPI "${ADMIN_USER}" "${ADMIN_PASSWORD}" "${USER_ID}" || true
    doguctl config --remove service_accounts/"${SERVICE}"
  }

  echo "Deleting service role service_account_role_${SERVICE}..."
  deleteRoleForServiceViaAPI "${ADMIN_USER}" "${ADMIN_PASSWORD}" "service_account_role_${SERVICE}" || true
fi

if [ -n "${REPO_TO_BE_DELETED}" ]; then
  echo "Deleting repository ${REPO_TO_BE_DELETED}..."
  deleteRepositoryViaAPI "${ADMIN_USER}" "${ADMIN_PASSWORD}" "${REPO_TO_BE_DELETED}" || true
fi
