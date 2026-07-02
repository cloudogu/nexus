#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# DoguV3-only init-container:
#   1. Materialize the /etc/ces/dogu_json/nexus/{current,<version>} layout that doguctl expects
#   2. Fetch the CES server certificate for the non-root nexus container
#   3. Wait until PostgreSQL accepts connections
#   4. Fix ownership of the persistent volumes for the nexus user (uid/gid 1000)
#
# Ownership must be fixed LAST: every doguctl invocation above runs as root (this container)
# and, as a side effect of just creating a registry client, eagerly creates
# /var/ces/config/local.yaml if it doesn't exist yet (see cloudogu/doguctl
# DoguFileConfigurationContext.checkLocalConfigFile) — owned by root. The later non-root
# nexus container would then fail with "permission denied" writing to that file.

mkdir -p /var/lib/nexus /var/ces/config

# --- 1. dogu_json layout ------------------------------------------------------
TARGET_DIR="/etc/ces/dogu_json/nexus"
SOURCE_DOGU_JSON="/dogu.json"

# Take the first "Version" line
DOGU_VERSION="$(awk -F'"' '/"Version"[[:space:]]*:/ {print $4; exit}' "${SOURCE_DOGU_JSON}")"
if [ -z "${DOGU_VERSION}" ]; then
  echo "unable to determine dogu version from ${SOURCE_DOGU_JSON}" >&2
  exit 1
fi

mkdir -p "${TARGET_DIR}"
printf '%s' "${DOGU_VERSION}" > "${TARGET_DIR}/current"
cp "${SOURCE_DOGU_JSON}" "${TARGET_DIR}/${DOGU_VERSION}"

echo "prepared dogu.json in ${TARGET_DIR} for to be used by doguctl"

# --- 2. CES server certificate -------------------------------------------------
# The main nexus container runs as the non-root nexus user and can't write into its own image-baked /etc/ssl/certs.
CERT_DIR="/dogu_v3/ca-certs"
mkdir -p "${CERT_DIR}"
doguctl config --global certificate/server.crt > "${CERT_DIR}/server.crt"

echo "wrote CES server certificate to ${CERT_DIR}/server.crt"

# --- 3. wait for PostgreSQL ---------------------------------------------------
DB_HOST="${POSTGRESQL_HOST:-postgresql}"
DB_PORT="${POSTGRESQL_PORT:-5432}"
DB_WAIT_TIMEOUT_SECONDS="${DB_WAIT_TIMEOUT_SECONDS:-300}"
DB_WAIT_INTERVAL_SECONDS=2

echo "waiting for PostgreSQL at ${DB_HOST}:${DB_PORT} (timeout ${DB_WAIT_TIMEOUT_SECONDS}s)..."
elapsed=0
while ! pg_isready -h "${DB_HOST}" -p "${DB_PORT}" -t "${DB_WAIT_INTERVAL_SECONDS}" -q; do
  if [ "${elapsed}" -ge "${DB_WAIT_TIMEOUT_SECONDS}" ]; then
    echo "PostgreSQL at ${DB_HOST}:${DB_PORT} not ready after ${DB_WAIT_TIMEOUT_SECONDS}s" >&2
    exit 1
  fi
  echo "PostgreSQL not ready yet, retrying in ${DB_WAIT_INTERVAL_SECONDS}s (waited ${elapsed}s/${DB_WAIT_TIMEOUT_SECONDS}s)..."
  sleep "${DB_WAIT_INTERVAL_SECONDS}"
  elapsed=$((elapsed + DB_WAIT_INTERVAL_SECONDS))
done

echo "PostgreSQL is accepting connections"

# --- 4. persistence ownership -------------------------------------------------
# Must run last (see header comment): fixes up anything doguctl created as root above.
chown -R 1000:1000 /var/lib/nexus /var/ces/config

echo "set ownership for /var/lib/nexus and /var/ces/config"
