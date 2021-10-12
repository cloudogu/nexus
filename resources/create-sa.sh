#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

{
  source nexus_api.sh
  source util.sh

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
  let NUMBER_OF_PARAMS--

  # Look for optional parameters
  i="${NUMBER_OF_PARAMS}"
  while [ $i -ge 1 ]; do
    params="${!i}"

    if [ "$(echo "${params}" | sed 's/=.*//g')" == "fullAccessRepository" ]; then
      USE_FULL_REPO_NAME="$(echo "${params}" | sed 's/fullAccessRepository=//g')"
      USE_FULL_REPO_TYPE="hosted"
      USE_FULL_REPO_FORMAT="raw"
      echo "Requesting full access repository to new repository [${USE_FULL_REPO_NAME}] of type [${USE_FULL_REPO_TYPE}] and format [${USE_FULL_REPO_FORMAT}]..."
    fi

    if [ "$(echo "${params}" | sed 's/=.*//g')" == "permissions" ]; then
      ADDITIONAL_PERMISSION="$(echo "\"${params}\"" | sed 's/permissions=//g' | sed 's/,/","/g')"
      echo "Requesting the following additional permissions [${ADDITIONAL_PERMISSION}]..."
    fi

    let i--
  done

  if [ ! -z "${USE_FULL_REPO_NAME}" ] && [ ! -z "${USE_FULL_REPO_TYPE}" ] && [ ! -z "${USE_FULL_REPO_FORMAT}" ]; then
    ADDITIONAL_PERMISSION="${ADDITIONAL_PERMISSION},\"nx-repository-view-${USE_FULL_REPO_FORMAT}-${USE_FULL_REPO_NAME}-*\""
    ADDITIONAL_PERMISSION="$(echo ${ADDITIONAL_PERMISSION} | sed "s/^,//g")"
  fi
  echo "Granting the following permissions [${ADDITIONAL_PERMISSION}]..."

  # create random schema suffix and password
  USER_ID=$(doguctl random -l 6 | tr '[:upper:]' '[:lower:]')
  USER_NAME="service_account_${SERVICE}_${USER_ID}"
  USER_PASSWORD=$(doguctl random)

  # admin credentials
  ADMIN_USER="$(doguctl config -e admin_user)"
  ADMIN_PASSWORD="$(doguctl config -e admin_pw)"

  if [ ! -z "${USE_FULL_REPO_NAME}" ] && [ ! -z "${USE_FULL_REPO_TYPE}" ] && [ ! -z "${USE_FULL_REPO_FORMAT}" ]; then
    echo "Creating repository [${USE_FULL_REPO_NAME}] of type [${USE_FULL_REPO_TYPE}] and format [${USE_FULL_REPO_FORMAT}]..."
    createRepositoryViaAPI "${ADMIN_USER}" "${ADMIN_PASSWORD}" "${USE_FULL_REPO_NAME}" "${USE_FULL_REPO_FORMAT}" "${USE_FULL_REPO_TYPE}"
  fi

  echo "Creating role [service_account_role_${SERVICE}]..."
  createRoleForServiceViaAPI "${ADMIN_USER}" "${ADMIN_PASSWORD}" "service_account_role_${SERVICE}" "${SERVICE}" "${ADDITIONAL_PERMISSION}"

  echo "Creating user [${USER_NAME}]..."
  createUserViaAPI "${ADMIN_USER}" "${ADMIN_PASSWORD}" "${USER_NAME}" "${USER_PASSWORD}" "${SERVICE}" "service_account_role_${SERVICE}"
} >/dev/null 2>&1

if [ ! -z "${USE_FULL_REPO_NAME}" ] && [ ! -z "${USE_FULL_REPO_TYPE}" ] && [ ! -z "${USE_FULL_REPO_FORMAT}" ]; then
  echo "repository: ${USE_FULL_REPO_NAME}"
fi
echo "username: ${USER_NAME}"
echo "password: ${USER_PASSWORD}"
