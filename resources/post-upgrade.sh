#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

doguctl config post_upgrade_running true
NEXUS_DATA_DIR=/var/lib/nexus
MIGRATION_HELPER_JAR="${NEXUS_DATA_DIR}/nexus-db-migrator-3.70.3-01.jar"

FROM_VERSION="${1}"
TO_VERSION="${2}"

if [[ $FROM_VERSION == 3.70.2* ]] && [[ $TO_VERSION == 3.73.0* ]]; then
  if [ ! -e "${MIGRATION_HELPER_JAR}" ]; then
    # try to download migration helper jar if it does not exist
    echo "trying to download the migration helper, warum auch immer"
    curl -s -L --retry 3 -o "${MIGRATION_HELPER_JAR}" "https://download.sonatype.com/nexus/nxrm3-migrator/nexus-db-migrator-3.70.3-01.jar"
  fi
  "${NEXUS_WORKDIR}/bin/nexus" stop
  # move the backup artifacts to the workdir because the jar expects them there
  find "${NEXUS_DATA_DIR}" -name "*.bak" -exec mv '{}' "${NEXUS_WORKDIR}" \;
  chown "nexus:nexus" "${MIGRATION_HELPER_JAR}"
  # run migration
  java -Xmx16G -Xms16G -XX:+UseG1GC -XX:MaxDirectMemorySize=28672M \
    -jar "${MIGRATION_HELPER_JAR}" --yes --content_migration=true --migration_type=h2

  # move migration artifact to final location
  rm -rf /var/lib/nexus/db/*
  mv "nexus.mv.db" "${NEXUS_DATA_DIR}/db"
  # give ownership to nexus user, otherwise db cannot be accessed by nexus process
  chown "nexus:nexus" "${NEXUS_DATA_DIR}/db/nexus.mv.db"
  doguctl config migratedDatabase "true"
  echo "Database migration completed. Nexus now runs on the H2 database"
  echo "Starting new Nexus version ${TO_VERSION}"
fi

doguctl config post_upgrade_running false