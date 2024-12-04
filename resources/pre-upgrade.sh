#!/bin/bash


set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC1091
source /util.sh

NEXUS_DATA_DIR=/var/lib/nexus

FROM_VERSION="${1}"
TO_VERSION="${2}"

if [[ $FROM_VERSION == 2* ]] && [[ $TO_VERSION == 3* ]]; then
    touch "${NEXUS_DATA_DIR}"/migration
fi

# database backup script needs to be written to a file from string, because it is needed in the old container
writeDatabaseBackupScriptToFile() {
  export BACKUP_TASK_NAME="orientDatabaseBackup"
  echo 'import org.sonatype.nexus.scheduling.TaskConfiguration; import org.sonatype.nexus.scheduling.TaskScheduler; def taskScheduler = container.lookup(TaskScheduler.class.getName()); TaskConfiguration config = taskScheduler.createTaskConfigurationInstance("db.backup"); config.setEnabled(true); config.setName("orientDatabaseBackup"); config.setString("location", "/opt/sonatype/nexus"); taskScheduler.submit(config);' > "${NEXUS_WORKDIR}/resources/nexusBackupOrientDBTask.groovy"
}

if [[ $FROM_VERSION == 3.70.2* ]] && [[ $TO_VERSION == 3.73.0* ]]; then
  echo "Starting migration to H2 database now"
  # check ram size, upgrade needs at least 16GB
  hasEnoughRAM=$(free -g | grep Mem: | awk '{print $2}')
  if [[ ${hasEnoughRAM} -ge 16 ]]; then
    echo "Not enough RAM for update. Exiting"
    exit 2
  fi
  NEXUS_USER="$(doguctl config -e admin_user)"
  NEXUS_PASSWORD="$(doguctl config -e admin_pw)"

  # remove any old backup artifacts
  find "${NEXUS_WORKDIR}" -name '*.bak*' -delete

  writeDatabaseBackupScriptToFile

  NEXUS_URL="http://localhost:8081/nexus" NEXUS_USER="${NEXUS_USER}" NEXUS_PASSWORD="${NEXUS_PASSWORD}" nexus-scripting execute "${NEXUS_WORKDIR}/resources/nexusBackupOrientDBTask.groovy"
  # wait for backup files to appear
  echo "Creating database backup. Depending on the size of the database this process may take a while.."
  spin='-\|/'
  i=0
  AMOUNT_OF_BACKUP_FILES="4"
  until [[ $(find "${NEXUS_WORKDIR}" -name '*.bak*' |  wc -l | grep "${AMOUNT_OF_BACKUP_FILES}") == "${AMOUNT_OF_BACKUP_FILES}" ]]; do
    i=$(( (i+1) %4 ))
    printf "\r${spin:$i:1}"
    sleep .3
  done
  echo "database backup created"
  find "${NEXUS_WORKDIR}" -name "*.bak" -exec mv '{}' "${NEXUS_DATA_DIR}" \;
  find "/jars" -name "*.jar" -exec mv '{}' "${NEXUS_WORKDIR}/jars" \;
fi
