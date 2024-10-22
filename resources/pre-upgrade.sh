#!/bin/bash


set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC1091
source /util.sh

NEXUS_DATA_DIR=/var/lib/nexus
MIGRATION_FILE_NAME="opt/sonatype/nexus/orient_backup.bak"
MIGRATION_HELPER_JAR="${NEXUS_DATA_DIR}/migration_helper.jar"

FROM_VERSION="${1}"
TO_VERSION="${2}"
echo "Executing pre upgrade"

if [[ $FROM_VERSION == 2* ]] && [[ $TO_VERSION == 3* ]]; then
    touch "${NEXUS_DATA_DIR}"/migration
fi

# TODO make this part easier
MAJOR_VERSION_INDEX=1
MINOR_VERSION_INDEX=2
BUGFIX_VERSION_INDEX=3
DOGU_VERSION_INDEX=4

# Returns true if X is less than or equal to Y; otherwise false
function versionXLessOrEqualThanY() {
  local sourceVersion="${1}"
  local targetVersion="${2}"

  if [[ "${sourceVersion}" == "${targetVersion}" ]]; then
    return 0
  fi

  local sourceMajor=0 sourceMinor=0 sourceBugfix=0 sourceDogu=0 \
        targetMajor=0 targetMinor=0 targetBugfix=0 targetDogu=0 \
        majorLessOrEqual=0 minorLessOrEqual=0 bugfixLessOrEqual=0

  if ! is_valid_version "${sourceVersion}"; then
    echo "ERROR: source dogu version ${sourceVersion} does not seem to be a semantic version"
    exit 1
  fi

  if ! is_valid_version "${targetVersion}"; then
    echo "ERROR: target dogu version ${targetVersion} does not seem to be a semantic version"
    exit 1
  fi

  sourceMajor="$(get_version "${sourceVersion}" "${MAJOR_VERSION_INDEX}")"
  targetMajor="$(get_version "${targetVersion}" "${MAJOR_VERSION_INDEX}")"
  if [[ $((sourceMajor)) -lt $((targetMajor)) ]]; then
    return 0
  fi

  majorLessOrEqual="$(versionXLessOrEqualThanY "${sourceMajor}" "${targetMajor}")"
  sourceMinor="$(get_version "${sourceVersion}" "${MINOR_VERSION_INDEX}")"
  targetMinor="$(get_version "${targetVersion}" "${MINOR_VERSION_INDEX}")"
  if [[ $((sourceMinor)) -lt $((targetMinor)) ]] && [[ ! $majorLessOrEqual ]]; then
    return 0
  fi

  minorLessOrEqual="$(versionXLessOrEqualThanY "${sourceMinor}" "${targetMinor}")"
  sourceBugfix="$(get_version "${sourceVersion}" "${BUGFIX_VERSION_INDEX}")"
  targetBugfix="$(get_version "${targetVersion}" "${BUGFIX_VERSION_INDEX}")"
  if [[ $((sourceBugfix)) -lt $((targetBugfix)) ]] && [[ ! $majorLessOrEqual ]] && [[ ! $minorLessOrEqual ]]; then
    return 0
  fi

  bugfixLessOrEqual="$(versionXLessOrEqualThanY "${sourceBugfix}" "${targetBugfix}")"
  sourceDogu="$(get_version "${sourceVersion}" "${DOGU_VERSION_INDEX}")"
  targetDogu="$(get_version "${targetVersion}" "${DOGU_VERSION_INDEX}")"
  if [[ $((sourceDogu)) -lt $((targetDogu)) ]] && [[ ! $majorLessOrEqual ]] && [[ ! $minorLessOrEqual ]] && [[ ! $bugfixLessOrEqual ]]; then
    return 0
  fi

  return 1
}

# get_version returns the value of the given semver index. If the input is not a valid semantic version
# the function exits with exit code 1
# MAJOR_VERSION  -> 1
# MINOR_VERSION  -> 2
# BUGFIX_VERSION -> 3
# DOGU_VERSION   -> 4
get_version() {
  local version index value
  version="${1}"
  index="${2}"
  value="0"
  if ! is_valid_version "${version}"; then
    echo "ERROR: dogu version ${version} does not seem to be a semantic version"
    exit 1
  fi
  value=${BASH_REMATCH[index]}
  echo "${value}"
}

is_valid_version() {
  local version
  version="${1}"
  declare -r semVerRegex='([0-9]+)\.([0-9]+)\.([0-9]+)-([0-9]+)'
  if [[ ! ${version} =~ ${semVerRegex} ]]; then
    return 1
  fi
}

waitForProcessKill() {
  local PID=$1
  while [ -e "/proc/${PID}" ]
  do
      sleep .6
  done
}

backupDatabase() {
  echo "import org.sonatype.nexus.scheduling.TaskConfiguration; import org.sonatype.nexus.scheduling.TaskSupport; def taskScheduler = container.lookup(TaskScheduler.class.getName()); def youSaid = args; return 'Hello. You said: ' + youSaid;" > "${NEXUS_WORKDIR}/resources/nexusBackupOrientDBTask.groovy"
echo '{
        "name": "backup-orient-db-for-migration24",
        "notes": "Backs up the existing OrientDB to perform migration to H2",
        "location": "",
        "enabled": "true",
        "type": "groovy",
        "content": "log.info(\"Hello, World!\")"
      }' >  "${NEXUS_WORKDIR}/resources/completeBackupJSON.json"
echo '{
        "name": "backup-orient-db-for-migration3",
        "notes": "Backs up the existing OrientDB to perform migration to H2",
        "enabled": "true",
        "type": "groovy"
      }' > "${NEXUS_WORKDIR}/resources/nexusBackupOrientDBTaskParameters.json"
}

if versionXLessOrEqualThanY "${FROM_VERSION}" "3.70.2-3" && ! versionXLessOrEqualThanY "${TO_VERSION}" "3.70.2-3"; then
  echo "Upgrading to ${TO_VERSION} requires a database migration. Starting migration to H2 database now"
  # check ram size, upgrade needs at least 16GB
  hasEnoughRAM=$(free -g | grep Mem: | awk '{print $2}')
  if [[ ${hasEnoughRAM} -ge 16 ]]; then
    echo "Not enough RAM for update. Exiting"
    exit 2
  fi

  backupDatabase
  "${NEXUS_WORKDIR}/bin/nexus" run &
    NEXUS_PID=$!

  # export so that nexus-scripting has access to url and user
  export NEXUS_URL="http://localhost:8081/nexus"
  export NEXUS_USER="$(doguctl config -e admin_user)"
  export NEXUS_PASSWORD="$(doguctl config -e admin_pw)"


  waitForHealthEndpoint "${NEXUS_USER}" "${NEXUS_PASSWORD}"

  # curl -v -u "${NEXUS_USER}:${NEXUS_PASSWORD}" -X POST --header 'Content-Type: application/json' \
  # http://localhost:8081/nexus/service/rest/v1/script \
  # -d "@${NEXUS_WORKDIR}/resources/completeBackupJSON.json"

  # curl -v -u "${NEXUS_USER}:${NEXUS_PASSWORD}" -X POST --header 'Content-Type: text/plain' \
  #  "http://localhost:8081/nexus/service/rest/v1/script/backup-orient-db-for-migration24/run"

  # NEXUS_PASSWORD="${NEXUS_PASSWORD}" \
  #   nexus-scripting execute --file-payload "${NEXUS_WORKDIR}/resources/nexusConfParameters.json" "${NEXUS_WORKDIR}/resources/proxyConfiguration.groovy"

  # echo "Rendering nexusConfParameters template"
  # doguctl template "${NEXUS_WORKDIR}/resources/nexusConfParameters.json.tpl" \
  #   "${NEXUS_WORKDIR}/resources/nexusConfParameters.json"

  NEXUS_PASSWORD="${NEXUS_PASSWORD}" nexus-scripting execute --file-payload "${NEXUS_WORKDIR}/resources/nexusBackupOrientDBTaskParameters.json" "${NEXUS_WORKDIR}/resources/nexusBackupOrientDBTask.groovy"
  while [ ! -e "/*.bak" ]
  do
      sleep .6
  done
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
