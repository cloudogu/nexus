#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

NEXUS_V1_URL="http://localhost:8082/nexus/service/rest/v1"

# This function creates a new repository via an API call against the nexus.
# The method requires one parameter:
# 1 = name of the repository
function createRepositoryViaAPI() {
  local repositoryName="${1}"

  curl --request POST \
  -u "${ADMIN_USER}":"${ADMIN_PASSWORD}" \
  --url "${NEXUS_V1_URL}"/repositories/"${REPOSITORY_TYPE}"/hosted \
  --header 'Content-Type: application/json' \
  --data "{
  \"name\": \"${repositoryName}\",
  \"online\": true,
  \"storage\": {
    \"blobStoreName\": \"default\",
    \"strictContentTypeValidation\": true,
    \"writePolicy\": \"allow_once\"
  },
  \"cleanup\": {
    \"policyNames\": [
      \"string\"
    ]
  },
  \"component\": {
    \"proprietaryComponents\": true
  },
  \"raw\": {
    \"contentDisposition\": \"ATTACHMENT\"
  }
}" >/dev/null 2>&1
}

# This function creates a new role via an API call against the nexus.
# The method requires no parameters.
function createRoleForServiceViaAPI() {
  curl --request POST \
  -u "${ADMIN_USER}":"${ADMIN_PASSWORD}" \
  --url "${NEXUS_V1_URL}"/security/roles \
  --header 'Content-Type: application/json' \
  --data "{
  \"id\": \"service_account_role_${SERVICE}\",
  \"name\": \"service_account_role_${SERVICE}\",
  \"description\": \"This is a special role created for the ${SERVICE}-service-account. Do not manually change or delete this role.\",
  \"privileges\": [
    \"nx-repository-view-raw-${SERVICE}-*\"
  ],
  \"roles\": [
  ]
}" >/dev/null 2>&1
}

# This function creates a new user via an API call against the nexus.
# The method requires two parameters:
# 1 = userID
# 2 = password of the user
function createUserViaAPI() {
  local userID="${1}"
  local password="${2}"

  curl --request POST \
  --url "${NEXUS_V1_URL}"/security/users \
  -u "${ADMIN_USER}":"${ADMIN_PASSWORD}" \
  --header 'Content-Type: application/json' \
  --data "{
  \"userId\": \"${userID}\",
  \"firstName\": \"${userID}\",
  \"lastName\": \"${userID}\",
  \"emailAddress\": \"${userID}@ces.ces\",
  \"password\": \"${password}\",
  \"status\": \"active\",
  \"roles\": [
    \"service_account_role_${SERVICE}\"
  ]
}" >/dev/null 2>&1
}

{
  source util.sh

  REPOSITORY_TYPE="$1"
  if [ X"${REPOSITORY_TYPE}" = X"" ]; then
      echo "using a raw repository as default repository type"
      REPOSITORY_TYPE="raw"
  fi

  SERVICE="$2"
  if [ X"${SERVICE}" = X"" ]; then
      echo "usage create-sa.sh servicename"
      exit 1
  fi

  # create random schema suffix and password
  USER_ID=$(doguctl random -l 6 | tr '[:upper:]' '[:lower:]')
  USER_NAME="service_account_${SERVICE}_${USER_ID}"
  USER_PASSWORD=$(doguctl random)

  # admin credentials
  ADMIN_USER="$(doguctl config -e admin_user)"
  ADMIN_PASSWORD="$(doguctl config -e admin_pw)"

  createRepositoryViaAPI "${SERVICE}"
  createRoleForServiceViaAPI
  createUserViaAPI "${USER_NAME}" "${USER_PASSWORD}"
} >/dev/null 2>&1

echo "repository: ${SERVICE}"
echo "username: ${USER_NAME}"
echo "password: ${USER_PASSWORD}"