#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC1091
source /util.sh

NEXUS_DATA_DIR=/var/lib/nexus
MIGRATION_HELPER_JAR_NAME="nexus-db-migrator.jar"
MIGRATION_HELPER_JAR="${NEXUS_DATA_DIR}/${MIGRATION_HELPER_JAR_NAME}"
NEXUS_WORKDIR=/opt/sonatype/nexus
TRUSTSTORE="${NEXUS_DATA_DIR}/truststore.jks"
DATABASE_USER=$(doguctl config -e sa-postgresql/username)
DATABASE_PASSWORD=$(doguctl config -e sa-postgresql/password)
DATABASE_DB=$(doguctl config -e sa-postgresql/database)

FROM_VERSION="${1}"
TO_VERSION="${2}"

waitForDatabaseBackup() {
  echo "Creating database backup. Depending on the size of the database this process may take a while.."
  spin='-\|/'
  i=0
  AMOUNT_OF_BACKUP_FILES="1"
  until [[ $(find "${NEXUS_DATA_DIR}/db" -name 'nexus-*.zip' |  wc -l | grep "${AMOUNT_OF_BACKUP_FILES}") == "${AMOUNT_OF_BACKUP_FILES}" ]]; do
    i=$(( (i+1) %4 ))
    printf "\r%s" "${spin:$i:1}"
    sleep .3
  done
  echo "Database backup created"
}

echo "executing post upgrade"
if [[ ($FROM_VERSION == 3.70.2* && $TO_VERSION == 3.82.0*) || ($FROM_VERSION == 3.75.0* && $TO_VERSION == 3.82.0*) ]]; then
  # Migration from H2 to postgresql database
  # this follows the official guide from https://help.sonatype.com/en/migrating-to-a-new-database.html#migrating-from-h2-to-postgresql
  echo "Starting migration from H2 to postgresql."
  # copy the migrator jar to the location nexus expects it to be in
  cp "$(find /jars -maxdepth 1 -name 'nexus-db-migrator-3.82*' | head -n1)" "${NEXUS_DATA_DIR}/db/${MIGRATION_HELPER_JAR_NAME}"

  # start nexus
  echo "Starting nexus"
  setNexusVmoptionsAndProperties
  setNexusProperties
  # start with nexus user, otherwise nexus creates elasticsearch directories with root user, which crashes nexus in startup
  su nexus -c '"${NEXUS_WORKDIR}/bin/nexus" run' &
    NEXUS_PID=$!

  # wait up to ten minutes for nexus to get ready before creating backup
  counter=0
  while [[ "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/nexus/service/rest/v1/status)" != "200" ]]; do
    if [ "$counter" -gt 120 ]; then
      echo "waited more than ten minutes for nexus to get ready"
      return 1
    fi
    counter=$((counter + 1))
    sleep 5
  done

  echo "triggering password re-encryption"
  curl --user "${ADMINUSER}:${ADMINPW}" \
    -X 'PUT' \
    "http://localhost:8081/nexus/service/rest/v1/secrets/encryption/re-encrypt" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -H 'X-Nexus-UI: true' \
    -d '{ "secretKeyId": "nexus-dynamic-secret"}'
  sleep 10
  echo "waiting"
  sleep 10
  echo "done?"

  # execute the H2 database backup groovy script
  echo "Creating H2 database backup"
  NEXUS_URL="http://localhost:8081/nexus" NEXUS_USER="$(doguctl config -e admin_user)" NEXUS_PASSWORD="$(doguctl config -e admin_pw)" nexus-scripting execute "${NEXUS_WORKDIR}/resources/createH2DatabaseBackupTask.groovy"
  waitForDatabaseBackup

  # nexus cannot be running while the migration is being performed
  echo "Stopping Nexus. There might be database errors as a result of this"
  kill -TERM "$NEXUS_PID" || true
  wait "$NEXUS_PID" || true

  echo "Migrating to postgresql"
  WORKDIR=$(pwd)
  cd "${NEXUS_DATA_DIR}/db"

  java -Xmx16G -Xms16G -XX:+UseG1GC -XX:MaxDirectMemorySize=28672M \
  -jar "${MIGRATION_HELPER_JAR_NAME}" \
  --migration_type=h2_to_postgres \
  --yes \
  --db_url="jdbc:postgresql://postgresql:5432/${DATABASE_DB}?user=${DATABASE_USER}&password=${DATABASE_PASSWORD}&currentSchema=public"

  cd "${WORKDIR}"

  # clean up postgresql db after migration as suggested by nexus
  echo "Cleaning up postgresql database after migrating."
  sql "VACUUM(FULL, ANALYZE, VERBOSE);"

  # delete db directory as it is not needed anymore
  rm -rf ${NEXUS_DATA_DIR}/db

  echo "The migration was successful. Nexus now uses the external postgres database"
fi

doguctl config upgrade_running "false"