#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC1091
source /util.sh

function startComponentRoutine() {
  local adminUser="${1}" adminPW="${2}"

  waitForNexus

  deleteOldComponents

  createNewComponents "${adminUser}" "${adminPW}" "${componentConfigs}"
}

function waitForNexus() {
  if ! doguctl wait --port 8082 --timeout 120; then
    echo "Nexus seems not to be started. Exiting."
    exit 1
  fi
}

function deleteOldComponents() {
  local componentIDs idList id
  # String array as json
  componentIDs=$(doguctl config "repository_component_ids")
  idList=$(splitJSONArrayToList "${componentIDs}")

  for id in ${idList}; do
    echo "Delete old uploaded component with ID: $id"
    deleteComponentViaAPI "${id}"
  done
}

function createNewComponents() {
  local adminUser="${1}" adminPW="${2}" doguConfigValue componentConfigsList componentConfig

  doguConfigValue=$(doguctl config --default "default" "repository_component_uploads")
  if [[ "${doguConfigValue}" == "default" ]]; then
    echo "No repository component uploads defined"
    return
  fi

  componentConfigsList=$(splitJSONArrayToList "${doguConfigValue}")

  for componentConfig in ${componentConfigsList}; do
    uploadComponent "${adminUser}" "${adminPW}" "${componentConfig}"
  done
}

function uploadComponent() {
  local adminUser="${1}" adminPW="${2}" componentConfig="${3}" repository formParams

  repository=$(getRepositoryParameter "${componentConfig}")
  formParams=$(getCurlComponentFormParameter "${componentConfig}")

  echo "Create component with params [$componentConfig] in repository: $repository"
  uploadComponentViaAPI "${adminUser}" "${adminPW}" "${repository}" "${formParams}"
}

function getRepositoryParameter() {
  local entry=$1
  echo "${entry}" | jq -r '.repository'
}

function getCurlComponentFormParameter() {
  local entry=$1 repository entryWithoutRepo formEntries

  repository=$(echo "${entry}" | jq -r '.repository')
  entryWithoutRepo=$(echo "${entry}" | jq 'del(.repository)')
  formEntries=$(splitJSONArrayToList "$(echo "${entryWithoutRepo}" | jq 'to_entries')")

  local curlFormParameterList=""

  for entry in ${formEntries}; do
    curlFormParameterList="$curlFormParameterList-F $(echo "$entry" | jq -r '.key')=$(echo "$entry" | jq -r '.value') "
  done

  echo "$curlFormParameterList"
}

function splitJSONArrayToList() {
  local json=$1
  echo "${json}" | jq -c '.[]'
}
