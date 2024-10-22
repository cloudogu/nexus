#!/bin/bash


set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC1091
source /util.sh
source /versions.sh

NEXUS_DATA_DIR=/var/lib/nexus
MIGRATION_FILE_NAME="opt/sonatype/nexus/orient_backup.bak"
MIGRATION_HELPER_JAR="${NEXUS_DATA_DIR}/migration_helper.jar"

FROM_VERSION="${1}"
TO_VERSION="${2}"
echo "Executing pre upgrade"

if [[ $FROM_VERSION == 2* ]] && [[ $TO_VERSION == 3* ]]; then
    touch "${NEXUS_DATA_DIR}"/migration
fi

writeDatabaseBackupScriptToFile() {
  echo 'import org.sonatype.nexus.scheduling.TaskConfiguration; import org.sonatype.nexus.scheduling.TaskScheduler; def taskScheduler = container.lookup(TaskScheduler.class.getName()); TaskConfiguration config = taskScheduler.createTaskConfigurationInstance("db.backup"); config.setEnabled(true); config.setName("orientDatabaseBackup"); config.setString("location", "/var/lib/nexus"); taskScheduler.submit(config); def youSaid = args; return "Hello. You said: " + youSaid;' > "${NEXUS_WORKDIR}/resources/nexusBackupOrientDBTask.groovy"
}

if versionXLessOrEqualThanY "${FROM_VERSION}" "3.70.2-3" && ! versionXLessOrEqualThanY "${TO_VERSION}" "3.70.2-3"; then
  echo "Upgrading to ${TO_VERSION} requires a database migration. Starting migration to H2 database now"
  # check ram size, upgrade needs at least 16GB
  hasEnoughRAM=$(free -g | grep Mem: | awk '{print $2}')
  if [[ ${hasEnoughRAM} -ge 16 ]]; then
    echo "Not enough RAM for update. Exiting"
    exit 2
  fi

  writeDatabaseBackupScriptToFile

  NEXUS_URL="http://localhost:8081/nexus" NEXUS_USER="$(doguctl config -e admin_user)" NEXUS_PASSWORD="$(doguctl config -e admin_pw)" nexus-scripting execute "${NEXUS_WORKDIR}/resources/nexusBackupOrientDBTask.groovy"
  while [ ! -e "${NEXUS_DATA_DIR}/*.bak" ]
  do
      sleep .6
  done
  echo "migration files created"
  # nexus cannot be running when database migration takes place
  "${NEXUS_WORKDIR}/bin/nexus" stop

  # download migration helper
  curl --location --retry 3 -o "${MIGRATION_HELPER_JAR}" \
    "https://download.sonatype.com/nexus/nxrm3-migrator/nexus-db-migrator-3.70.2-01.jar"

  # run migration
  java -Xmx16G -Xms16G -XX:+UseG1GC -XX:MaxDirectMemorySize=28672M \
    -jar "${MIGRATION_HELPER_JAR}" --yes --migration_type=h2

  # move migration artifact to final location
  mv "nexus.mv.db" "${NEXUS_DATA_DIR}/db"
  echo "nexus.datastore.enabled=true" >>${NEXUS_DATA_DIR}/etc/nexus.properties

  # finally remove migration file from volume
  rm "${MIGRATION_FILE}"
  rmdir "${NEXUS_DATA_DIR}/h2migration"
fi
