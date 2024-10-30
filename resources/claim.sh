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

ONCE_LOCK="claim/once.lock"

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
      doguctl config "${ONCE_LOCK}" "true"
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

if [[ "$(doguctl config --default "false" "${ONCE_LOCK}")" == "false" ]]; then
  echo "Executing claim once..."
  claim_once
else
  echo "Claim once was already executed. Skipping..."
fi

claim_always
