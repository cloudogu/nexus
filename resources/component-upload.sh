#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

LOCAL_CONFIG_KEY_CURRENT_COMPONENT_IDS="current_repository_component_ids"
COMPONENT_CONFIG_KEY="repository_component_uploads"

# shellcheck disable=SC1091
source /nexus_api.sh

function startComponentRoutine() {
  local adminUser="${1}" adminPW="${2}"

  waitForNexus
  deleteOldComponents "${adminUser}" "${adminPW}"
  createNewComponents "${adminUser}" "${adminPW}"
}

function waitForNexus() {
  if ! doguctl wait --port 8081 --timeout 120; then
    echo "Nexus seems not to be started. Exiting."
    exit 1
  fi
}

function deleteOldComponents() {
  local adminUser="${1}" adminPW="${2}" componentIDs id
  componentIDs=$(doguctl config --default "default" "${LOCAL_CONFIG_KEY_CURRENT_COMPONENT_IDS}")
  if [[ "${componentIDs}" == "default" ]]; then
    echo "No old component ids available. Skip Deletion."
    return
  fi

  for id in ${componentIDs}; do
    echo "Delete old uploaded component with ID: $id"
    deleteComponentViaAPI "${adminUser}" "${adminPW}" "${id}"
  done
}

function createNewComponents() {
  local adminUser="${1}" adminPW="${2}" doguConfigValue componentConfigsList componentConfig repo

  doguConfigValue=$(doguctl config --default "default" "${COMPONENT_CONFIG_KEY}")
  if [[ "${doguConfigValue}" == "default" ]]; then
    echo "No repository component uploads defined. Skip upload."
    return
  fi

  componentConfigsList=$(splitJSONArrayToList "${doguConfigValue}")

  # For data consistency, we need the component ids of the uploaded component.
  # On dogu restart, we delete all components by ids and recreate them.
  # For simplicity, we track all used repositorys, fetch components from these at the end and select all id with the dogu-tool-admin as uploader
  # otherwise we have to handle with filename and paths from the different formular fields and assets.
  declare -A repositorys

  for componentConfig in ${componentConfigsList}; do
    repo=$(getRepositoryParameter "${componentConfig}")
    repositorys[${repo}]=""
    uploadComponent "${adminUser}" "${adminPW}" "${componentConfig}"
  done

  saveComponentIDsFromRepositorys "${adminUser}" "${adminPW}" "$(declare -p repositorys)"
}

function uploadComponent() {
  local adminUser="${1}" adminPW="${2}" componentConfig="${3}" repository formParams

  repository=$(getRepositoryParameter "${componentConfig}")
  formParams=$(getCurlComponentFormParameter "${componentConfig}")

  echo "Create component in repository $repository with params:"$'\n'"[$componentConfig]"
  uploadComponentViaAPI "${adminUser}" "${adminPW}" "${repository}" "${formParams}"
}

function saveComponentIDsFromRepositorys() {
  local adminUser="${1}" adminPW="${2}" repositoryHashMapStr="${3}" ids idList repoKey
  local -A repositorys
  eval "$repositoryHashMapStr"

  idList=""
  for repoKey in "${!repositorys[@]}"; do
    echo "Getting IDs for repository $repoKey"
    ids="$(getComponentIDsByUploaderInRepository "${adminUser}" "${adminPW}" "dogu-tool-admin" "${repoKey}")"
    idList+=$'\n'"${ids}"
  done

  doguctl config "${LOCAL_CONFIG_KEY_CURRENT_COMPONENT_IDS}" "${idList}"
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

# make the script only run when executed, not when sourced from bats tests)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  startComponentRoutine "$@"
fi