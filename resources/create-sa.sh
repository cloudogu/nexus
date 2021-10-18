#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

{
  # shellcheck disable=SC1091
  source /nexus_api.sh
  # shellcheck disable=SC1091
  source /util.sh

  USE_FULL_REPO_NAME=""
  USE_FULL_REPO_TYPE=""
  USE_FULL_REPO_FORMAT=""
  ADDITIONAL_PERMISSION=""
  NUMBER_OF_PARAMS=$#

  if [ "${NUMBER_OF_PARAMS}" -le 0 ]; then
    echo "usage create-sa.sh [optional parameters] <service name>"
    exit 1
  fi

  # Get the latest parameter as service name
  SERVICE="${!NUMBER_OF_PARAMS}"
  echo "Create service account for service: ${SERVICE}"
  ((NUMBER_OF_PARAMS--))

  # Look for optional parameters
  i="${NUMBER_OF_PARAMS}"
  while [ $i -ge 1 ]; do
    params="${!i}"

    if [ "${params//=*/}" == "fullAccessRepository" ]; then
      USE_FULL_REPO_NAME="${params//fullAccessRepository=/}"
      USE_FULL_REPO_TYPE="hosted"
      USE_FULL_REPO_FORMAT="raw"
      echo "Requesting full access repository to new repository [${USE_FULL_REPO_NAME}] of type [${USE_FULL_REPO_TYPE}] and format [${USE_FULL_REPO_FORMAT}]..."
    fi

    if [ "${params//=*/}" == "permissions" ]; then
      ADDITIONAL_PERMISSION="$(echo "\"${params}\"" | sed 's/permissions=//g' | sed 's/,/","/g')"
      echo "Requesting the following additional permissions [${ADDITIONAL_PERMISSION}]..."
    fi

    ((i--))
  done

  if [ -n "${USE_FULL_REPO_NAME}" ] && [ -n "${USE_FULL_REPO_TYPE}" ] && [ -n "${USE_FULL_REPO_FORMAT}" ]; then
    ADDITIONAL_PERMISSION="${ADDITIONAL_PERMISSION},\"nx-repository-view-${USE_FULL_REPO_FORMAT}-${USE_FULL_REPO_NAME}-*\""
    # shellcheck disable=SC2001
    ADDITIONAL_PERMISSION="$(echo "${ADDITIONAL_PERMISSION}" | sed "s/^,//g")"
  fi
  echo "Granting the following permissions [${ADDITIONAL_PERMISSION}]..."

  # create random schema suffix and password
  USER_ID=$(doguctl random -l 6 | tr '[:upper:]' '[:lower:]')
  USER_NAME="service_account_${SERVICE}_${USER_ID}"
  USER_PASSWORD=$(doguctl random)

  # admin credentials
  ADMIN_USER="$(doguctl config -e admin_user)"
  ADMIN_PASSWORD="$(doguctl config -e admin_pw)"

  if [ -n "${USE_FULL_REPO_NAME}" ] && [ -n "${USE_FULL_REPO_TYPE}" ] && [ -n "${USE_FULL_REPO_FORMAT}" ]; then
    echo "Creating repository [${USE_FULL_REPO_NAME}] of type [${USE_FULL_REPO_TYPE}] and format [${USE_FULL_REPO_FORMAT}]..."
    createRepositoryViaAPI "${ADMIN_USER}" "${ADMIN_PASSWORD}" "${USE_FULL_REPO_NAME}" "${USE_FULL_REPO_FORMAT}" "${USE_FULL_REPO_TYPE}"
  fi

  echo "Creating role [service_account_role_${SERVICE}]..."
  createRoleForServiceViaAPI "${ADMIN_USER}" "${ADMIN_PASSWORD}" "service_account_role_${SERVICE}" "${SERVICE}" "${ADDITIONAL_PERMISSION}"

  echo "Creating user [${USER_NAME}]..."
  createUserViaAPI "${ADMIN_USER}" "${ADMIN_PASSWORD}" "${USER_NAME}" "${USER_PASSWORD}" "${SERVICE}" "service_account_role_${SERVICE}"
  doguctl config service_accounts/"${SERVICE}" "${USER_NAME}"
} >/dev/null 2>&1

if [ -n "${USE_FULL_REPO_NAME}" ] && [ -n "${USE_FULL_REPO_TYPE}" ] && [ -n "${USE_FULL_REPO_FORMAT}" ]; then
  echo "repository: ${USE_FULL_REPO_NAME}"
fi
echo "username: ${USER_NAME}"
echo "password: ${USER_PASSWORD}"
