#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

if ! doguctl wait --port 8081 --timeout 120; then 
  echo "Nexus seems not to be started. Exiting."
  exit 1
fi

ONCE_LOCK="/var/lib/nexus/claim.once"

export NEXUS_USER="admin"
# NEXUS_SERVER is already set in Dockerfile

function claim() {
  CLAIM="${1}"
  LOCK="${2}"
  PLAN=$(mktemp)
  if doguctl config claim/"${CLAIM}" > "${PLAN}"; then
    echo "Getting current admin password"
    local nexusPassword
    nexusPassword=$(doguctl config -e "admin_password")

    echo "exec claim ${CLAIM}"
    NEXUS_PASSWORD="${nexusPassword}" \
      nexus-claim plan -i "${PLAN}" -o "-" | \
    NEXUS_PASSWORD="${nexusPassword}" \
      nexus-claim apply -i "-"

    if [[ "${LOCK}" != "" ]]; then
      echo 1 > "${ONCE_LOCK}"
    fi
  fi
  rm -f "${PLAN}"
}

function claim_once() {
  claim "once" "${ONCE_LOCK}"
}

function claim_always() {
  claim "always" ""
}

if [[ ! -f "${ONCE_LOCK}" ]]; then
  claim_once
fi

claim_always
