#!/bin/bash


set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC1091
source /util.sh

NEXUS_DATA_DIR=/var/lib/nexus
MIGRATION_HELPER_JAR_NAME="nexus-db-migrator-3.88.0-08.jar"
MIGRATION_HELPER_JAR="${NEXUS_DATA_DIR}/${MIGRATION_HELPER_JAR_NAME}"

FROM_VERSION="${1}"
TO_VERSION="${2}"

# upgrade_running key blocks the execution of the startup script
doguctl config upgrade_running "true"

if [[ $FROM_VERSION == 2* ]] && [[ $TO_VERSION == 3* ]]; then
    touch "${NEXUS_DATA_DIR}"/migration
fi

# versionXLessOrEqualThanY returns true if X is less than or equal to Y; otherwise false
function versionXLessOrEqualThanY() {
  local sourceVersion="${1}"
  local targetVersion="${2}"

  if [[ "${sourceVersion}" == "${targetVersion}" ]]; then
    echo "upgrade to same version"
    return 0
  fi

  declare -r semVerRegex='([0-9]+)\.([0-9]+)\.([0-9]+)-([0-9]+)'

   sourceMajor=0
   sourceMinor=0
   sourceBugfix=0
   sourceDogu=0
   targetMajor=0
   targetMinor=0
   targetBugfix=0
   targetDogu=0

  if [[ ${sourceVersion} =~ ${semVerRegex} ]]; then
    sourceMajor=${BASH_REMATCH[1]}
    sourceMinor="${BASH_REMATCH[2]}"
    sourceBugfix="${BASH_REMATCH[3]}"
    sourceDogu="${BASH_REMATCH[4]}"
  else
    echo "ERROR: source dogu version ${sourceVersion} does not seem to be a semantic version"
    exit 1
  fi

  if [[ ${targetVersion} =~ ${semVerRegex} ]]; then
    targetMajor=${BASH_REMATCH[1]}
    targetMinor="${BASH_REMATCH[2]}"
    targetBugfix="${BASH_REMATCH[3]}"
    targetDogu="${BASH_REMATCH[4]}"
  else
    echo "ERROR: target dogu version ${targetVersion} does not seem to be a semantic version"
    exit 1
  fi

  if [[ $((sourceMajor)) -lt $((targetMajor)) ]] ; then
    return 0;
  fi
  if [[ $((sourceMajor)) -le $((targetMajor)) && $((sourceMinor)) -lt $((targetMinor)) ]] ; then
    return 0;
  fi
  if [[ $((sourceMajor)) -le $((targetMajor)) && $((sourceMinor)) -le $((targetMinor)) && $((sourceBugfix)) -lt $((targetBugfix)) ]] ; then
    return 0;
  fi
  if [[ $((sourceMajor)) -le $((targetMajor)) && $((sourceMinor)) -le $((targetMinor)) && $((sourceBugfix)) -le $((targetBugfix)) && $((sourceDogu)) -lt $((targetDogu)) ]] ; then
    return 0;
  fi

  return 1
}


# database backup script needs to be written to a file from string, because it is needed in the old container
writeDatabaseBackupScriptToFile() {
  export BACKUP_TASK_NAME="orientDatabaseBackup"
  echo 'import org.sonatype.nexus.scheduling.TaskConfiguration; import org.sonatype.nexus.scheduling.TaskScheduler; def taskScheduler = container.lookup(TaskScheduler.class.getName()); TaskConfiguration config = taskScheduler.createTaskConfigurationInstance("db.backup"); config.setEnabled(true); config.setName("orientDatabaseBackup"); config.setString("location", "/opt/sonatype/nexus"); taskScheduler.submit(config);' > "${NEXUS_WORKDIR}/resources/nexusBackupOrientDBTask.groovy"
}

# OrientDB needs to be migrated to H2 in this upgrade
if [[ $FROM_VERSION == 3.70.2* ]] && [[ $TO_VERSION == 3.82.0* ]]; then
  echo "Starting migration to H2 database now"

  if [ ! -e "/jars/${MIGRATION_HELPER_JAR_NAME}" ]; then
    # try to download migration helper jar if it does not exist
    echo "downloading migrator jar"
    mkdir -p /jars
    curl -s -L --retry 3 -o /jars/"${MIGRATION_HELPER_JAR_NAME}" "https://download.sonatype.com/nexus/nxrm3-migrator/${MIGRATION_HELPER_JAR_NAME}"
  fi
  NEXUS_USER="$(doguctl config -e admin_user)"
  NEXUS_PASSWORD="$(doguctl config -e admin_pw)"

  # remove any old backup artifacts
  rm -rf '*.bak'

  writeDatabaseBackupScriptToFile

  NEXUS_URL="http://localhost:8081/nexus" NEXUS_USER="${NEXUS_USER}" NEXUS_PASSWORD="${NEXUS_PASSWORD}" nexus-scripting execute "${NEXUS_WORKDIR}/resources/nexusBackupOrientDBTask.groovy"
  # wait for backup files to appear
  echo "Creating database backup. Depending on the size of the database this process may take a while.."
  spin='-\|/'
  i=0
  AMOUNT_OF_BACKUP_FILES="4"
  until [[ $(find "${NEXUS_WORKDIR}" -name '*.bak*' |  wc -l | grep "${AMOUNT_OF_BACKUP_FILES}") == "${AMOUNT_OF_BACKUP_FILES}" ]]; do
    i=$(( (i+1) %4 ))
    printf "\r%s" "${spin:$i:1}"
    sleep .3
  done
  echo "Database backup created"
  cp -fr /jars/* "${NEXUS_DATA_DIR}"

  "${NEXUS_WORKDIR}/bin/nexus" stop
  chown "nexus:nexus" "${MIGRATION_HELPER_JAR}"
  # check ram size, upgrade needs at least 16GB
  availableRAM=$(free -g | grep Mem: | awk '{print $2}')
  if [[ ${availableRAM} -le 16 ]]; then
    echo "This system does not have 16gb of ram, as suggested by nexus. The migration will be attempted but might fail because of this"
  fi
  # run migration
  allocatedRAM=$((availableRAM > 16 ? 16 : availableRAM))
  java "-Xmx${allocatedRAM}G" "-Xms${allocatedRAM}G" -XX:+UseG1GC -XX:MaxDirectMemorySize=28672M \
    -jar "${MIGRATION_HELPER_JAR}" --yes --content_migration=true --migration_type=h2

  # move migration artifact to final location
  mkdir "${NEXUS_DATA_DIR}"/olddb
  mv "${NEXUS_DATA_DIR}"/db/* "${NEXUS_DATA_DIR}"/olddb
  mv "nexus.mv.db" "${NEXUS_DATA_DIR}/db"
  # give ownership to nexus user, otherwise db cannot be accessed by nexus process
  chown "nexus:nexus" "${NEXUS_DATA_DIR}/db/nexus.mv.db"
  doguctl config migratedDatabase "true"
  rm -rf "${MIGRATION_HELPER_JAR}"

  echo "Database migration completed. Nexus now runs on the H2 database"
  echo "Starting new Nexus version ${TO_VERSION}"
fi

# migration from the old once.lock to the new once.timestamp
# ensure that claim/once will not be executed for this upgrade if once.lock is set to true
if versionXLessOrEqualThanY "$FROM_VERSION" "3.75.0-3" &&
[[ "$(doguctl config --default "false" "claim/once.lock")" == "true" ]]; then
  currentDate=$(date "+%Y-%m-%d %H:%M:%S")
  doguctl config "claim/once.timestamp_last" "${currentDate}"
fi