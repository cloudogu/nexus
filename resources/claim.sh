#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

ADMINUSER="${1}"
ADMINPW="${2}"

if ! doguctl wait --port 8081 --timeout 120; then 
  echo "Nexus seems not to be started. Exiting."
  exit 1
fi

ONCE_TIMESTAMP="claim/once.timestamp"
ONCE_TIMESTAMP_LAST="claim/once.timestamp_last"

# NEXUS_URL is already set correctly
# NEXUS_SERVER is already set in Dockerfile
export NEXUS_USER="${ADMINUSER}"

function claim() {
  CLAIM="${1}"
  PLAN=$(mktemp)

  if doguctl config claim/"${CLAIM}" > "${PLAN}"; then
    echo "exec claim ${CLAIM}"
    NEXUS_PASSWORD="${ADMINPW}" \
      nexus-claim plan -i "${PLAN}" -o "-" | \
    NEXUS_PASSWORD="${ADMINPW}" \
      nexus-claim apply -i "-"
    if [[ "${CLAIM}" == "once" ]]; then
      local currentDate
      currentDate=$(date "+%Y-%m-%d %H:%M:%S")
      doguctl config "${ONCE_TIMESTAMP_LAST}" "${currentDate}"
    fi
  fi
  rm -f "${PLAN}"
}

function claim_once() {
  claim "once"
}

function claim_always() {
  claim "always"
}

function getTimestampFromConfig() {
  local configKey="${1}"
  local exitCode=0

  result=$(doguctl config "${configKey}" --default "1970-01-01") || exitCode=$?
  if [[ "${exitCode}" != "0" ]]; then
    echo 0
    return
  fi

  local timestamp
  timestamp=$(date -d "${result}" +%s) || exitCode=$?
  if [[ "${exitCode}" != "0" ]]; then
    echo 0
    return
  fi

  echo "$timestamp"
}

onceTimestamp=$(getTimestampFromConfig "${ONCE_TIMESTAMP}")
onceTimestampLast=$(getTimestampFromConfig "${ONCE_TIMESTAMP_LAST}")

if [[ "${onceTimestamp}" -ge "${onceTimestampLast}"  ]]; then
  echo "Executing claim once..."
  claim_once
else
  echo "Claim once was already executed. Skipping..."
fi

claim_always
