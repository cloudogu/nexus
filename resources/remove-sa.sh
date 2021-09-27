#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

NEXUS_V1_URL="http://localhost:8082/nexus/service/rest/v1"

# This function deletes the service role via an API call against the nexus.
# The method requires no parameters:
function deleteRoleForServiceViaAPI() {
  local roleID="service_account_role_${SERVICE}"

  curl --request DELETE \
  -u "${ADMIN_USER}":"${ADMIN_PASSWORD}" \
  --url "${NEXUS_V1_URL}"/security/roles/"${roleID}"
}

# This function deletes an existing user via an API call against the nexus.
# The method requires one parameters:
# 1 = userID
function deleteUserViaAPI() {
  local userID="${1}"
  curl --request DELETE \
  -u "${ADMIN_USER}":"${ADMIN_PASSWORD}" \
  --url "${NEXUS_V1_URL}"/security/users/"${USER}"
}

source util.sh

SERVICE="${1}"
if [ X"${SERVICE}" = X"" ]; then
    echo "usage remove-sa.sh servicename"
    exit 1
fi

# admin credentials
ADMIN_USER="$(doguctl config -e admin_user)"
ADMIN_PASSWORD="$(doguctl config -e admin_pw)"

# remove service user
echo "Remove service account for ${SERVICE}..."
RESPONSE="$(sql "SELECT id FROM user WHERE (id LIKE 'service_account_${SERVICE}_%')")"
echo "${RESPONSE}"
USER_ID=$(echo "${RESPONSE}" | grep '|' | grep "${SERVICE}" | sed 's/|//g' | sed 's/[0-9]*\s*//')
echo "Users: ${USER_ID}"

IFS=$'\n' a=(${USER_ID})
for i in "${!a[@]}"
do
  USER="${a[i]}"
  echo "Delete user: ${USER}"

  # remove service user
  deleteUserViaAPI ${USER}
done

# delete the role
deleteRoleForServiceViaAPI

# do not delete the repository as it contains data