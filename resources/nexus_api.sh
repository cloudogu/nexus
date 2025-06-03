#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

NEXUS_V1_URL="http://localhost:8082/nexus/service/rest/v1"

#######################################
# This function creates a new repository via an API call against the nexus.
# GLOBALS:
#   NEXUS_V1_URL
# ARGUMENTS:
#   #1 - username for the request
#   #2 - password for the request
#   #3 - name of the repository
#   #4 - format of the repository
#   #5 - type of the repository
# OUTPUTS:
#   The request data send to the endpoint
# RETURN:
#   0 if succeeds, non-zero on error
#######################################
function createRepositoryViaAPI() {
  local user="$1"
  local pass="$2"
  local name="$3"
  local format="$4"
  local type="$5"

  curl --request POST -v\
    --user "${user}":"${pass}" \
    --header 'Content-Type: application/json' \
    --data "{\"name\":\"${name}\",\"online\":true,\"storage\":{\"blobStoreName\":\"default\",\"strictContentTypeValidation\":true,\"writePolicy\":\"allow\"},\"cleanup\":{\"policyNames\":[\"string\"]},\"component\":{\"proprietaryComponents\":true},\"raw\":{\"contentDisposition\":\"ATTACHMENT\"}}" \
    --url "${NEXUS_V1_URL}"/repositories/"${format}"/"${type}"
}

#######################################
# This function delete an existing repository via an API call against the nexus.
# GLOBALS:
#   NEXUS_V1_URL
# ARGUMENTS:
#   #1 - username for the request
#   #2 - password for the request
#   #3 - name of the repository
# OUTPUTS:
#   The response from the endpoint
# RETURN:
#   0 if succeeds, non-zero on error
#######################################
function deleteRepositoryViaAPI() {
  local user="$1"
  local pass="$2"
  local name="$3"

  curl --request DELETE \
    --user "${user}":"${pass}" \
    --url "${NEXUS_V1_URL}"/repositories/"${name}"
}

#######################################
# This function creates a new service role via an API call against the nexus.
# GLOBALS:
#   NEXUS_V1_URL
# ARGUMENTS:
#   #1 - username for the request
#   #2 - password for the request
#   #3 - name of the role to create
#   #4 - the service for that the user should be created for
#   #5 - a list containing the permission granted to the newly created role. For example:
#       "nx-repository-view-docker-*-read","nx-repository-view-maven-*-read"
# OUTPUTS:
#   The request data send to the endpoint
# RETURN:
#   0 if succeeds, non-zero on error
#######################################
function createRoleForServiceViaAPI() {
  local user="$1"
  local pass="$2"
  local roleName="$3"
  local serviceName="$4"
  local permissions="$5"

  curl --request POST \
    --user "${user}":"${pass}" \
    --header 'Content-Type: application/json' \
    --data "{\"id\":\"${roleName}\",\"name\":\"${roleName}\",\"description\":\"This is a special role created for the ${serviceName}-service-account. Do not manually change or delete this role.\",\"privileges\":[${permissions}],\"roles\":[]}" \
    --url "${NEXUS_V1_URL}"/security/roles
}

#######################################
# This function deletes the service role via an API call against the nexus.
# GLOBALS:
#   NEXUS_V1_URL
# ARGUMENTS:
#   #1 - username for the request
#   #2 - password for the request
#   #3 - Name of the role to delete
# OUTPUTS:
#   The response from the endpoint
# RETURN:
#   0 if succeeds, non-zero on error
#######################################
function deleteRoleForServiceViaAPI() {
  local user="$1"
  local pass="$2"
  local roleName="$3"

  curl --request DELETE \
    --user "${user}":"${pass}" \
    --url "${NEXUS_V1_URL}"/security/roles/"${roleName}"
}

#######################################
# This function creates a new user via an API call against the nexus.
# GLOBALS:
#   NEXUS_V1_URL
# ARGUMENTS:
#   #1 - username for the request
#   #2 - password for the request
#   #3 - the ID of the user
#   #4 - the password for the user
#   #5 - the service for that the user should be created for
#   #6 - a role that should be assigned to the user
# OUTPUTS:
#   The request data send to the endpoint
# RETURN:
#   0 if succeeds, non-zero on error
#######################################
function createUserViaAPI() {
  local user="$1"
  local pass="$2"
  local userID="$3"
  local password="$4"
  local service="$5"
  local role="$6"

  curl --request POST \
    --user "${user}":"${pass}" \
    --header 'Content-Type: application/json' \
    --data "{\"userId\":\"${userID}\",\"firstName\":\"This is a special user created for the ${service}-service-account. Do not manually change or delete this user.\",\"lastName\":\"DO NOT DELETE!\",\"emailAddress\":\"${userID}@ces.ces\",\"password\":\"${password}\",\"status\":\"active\",\"roles\":[\"${role}\"]}" \
    --url "${NEXUS_V1_URL}"/security/users
}

#######################################
# This function deletes an existing user via an API call against the nexus.
# GLOBALS:
#   NEXUS_V1_URL
# ARGUMENTS:
#   #1 - username for the request
#   #2 - password for the request
#   #3 - the ID of the user that should be deleted
# OUTPUTS:
#   The response from the endpoint
# RETURN:
#   0 if succeeds, non-zero on error
#######################################
function deleteUserViaAPI() {
  local user="$1"
  local pass="$2"
  local userID="$3"

  curl --request DELETE \
    --user "${user}":"${pass}" \
    --url "${NEXUS_V1_URL}"/security/users/"${userID}"
}

#######################################
# This function deletes an existing component by its id.
# GLOBALS:
#   NEXUS_V1_URL
# ARGUMENTS:
#   #1 - username for the request
#   #2 - password for the request
#   #3 - the ID of the component that should be deleted
# OUTPUTS:
#   The response from the endpoint
# RETURN:
#   0 if succeeds, non-zero on error
#######################################
function deleteComponentViaAPI() {
  local user="$1" pass="$2" id="$3"

  curl -u "${user}":"${pass}" -X DELETE "${NEXUS_V1_URL}/service/rest/v1/components/${id}"
}

#######################################
# This function creates or updates a component.
# GLOBALS:
#   NEXUS_V1_URL
# ARGUMENTS:
#   #1 - username for the request
#   #2 - password for the request
#   #3 - the repository of the component
#   #4 - the form params for the specific repository type
#        See [Components API](https://help.sonatype.com/en/components-api.html#ComponentsAPI-UploadComponent).
# OUTPUTS:
#   The response from the endpoint
# RETURN:
#   0 if succeeds, non-zero on error
#######################################
function uploadComponentViaAPI() {
  local user="$1" pass="$2" repository="$3" formParams="$4"

  curl -u "${user}:${pass}" -X POST "${NEXUS_V1_URL}/service/rest/v1/components?repository${repository}" "${formParams}"
}
