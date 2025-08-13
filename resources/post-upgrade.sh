#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC1091
source /util.sh

NEXUS_DATA_DIR=/var/lib/nexus
MIGRATION_HELPER_JAR_NAME="nexus-db-migrator-3.70.3-01.jar"
MIGRATION_HELPER_JAR="${NEXUS_DATA_DIR}/${MIGRATION_HELPER_JAR_NAME}"
NEXUS_WORKDIR=/opt/sonatype/nexus

FROM_VERSION="${1}"
TO_VERSION="${2}"
echo "executing pre upgrade"
sleep 600
if [[ $FROM_VERSION == 3.70.2* ]] && [[ $TO_VERSION == 3.82.0* ]]; then
  echo "executing postgresql migration"
  # migrator jar kopieren
  cp /jars/nexus-db-migrator-3.70.3-01.jar "${MIGRATION_HELPER_JAR}"
  echo "1"
  # nexus hochfahren
  "${NEXUS_WORKDIR}/bin/nexus" run &
    NEXUS_PID=$!
  echo "2"
  # Admin - Backup H2 Database task ausführen
  NEXUS_URL="http://localhost:8081/nexus" NEXUS_USER="$(doguctl config -e admin_user)" NEXUS_PASSWORD="$(doguctl config -e admin_pw)" nexus-scripting execute "${NEXUS_WORKDIR}/resources/createH2DatabaseBackupTask.groovy"
  echo "3"
  # Nexus herunterfahren
  kill -TERM "$NEXUS_PID" || true
  wait "$NEXUS_PID" || true
  echo "4"
  # postgres Konfigurations-Command in $data-dir/db ausführen
  DATABASE_USER=$(doguctl config -e sa-postgresql/username)
  DATABASE_PASSWORD=$(doguctl config -e sa-postgresql/password)
  DATABASE_DB=$(doguctl config -e sa-postgresql/database)
  FQDN=$(doguctl config --global fqdn)
  echo "5"
  WORKDIR=$(pwd)
  cd "${NEXUS_DATA_DIR}/db"
  java -Xmx16G -Xms16G -XX:+UseG1GC -XX:MaxDirectMemorySize=28672M \
  -jar nexus-db-migrator-*.jar \
  --migration_type=h2_to_postgres \
  --db_url="jdbc:postgresql://${FQDN}:5432/nexus?user=${DATABASE_USER}&password=${DATABASE_PASSWORD}&currentSchema=${DATABASE_DB}"
  cd "${WORKDIR}"
  echo "6"
  # Postgres db aufräumen: reclaim storage occupied by obsoleted tuples left from the migration
  psql -u "${DATABASE_USER}" -W "${DATABASE_PASSWORD}" -d "${DATABASE_DB}" -c "VACUUM(FULL, ANALYZE, VERBOSE);"
  echo "7"
  # start nexus
  # wird in startup.sh sowieso getan
fi
