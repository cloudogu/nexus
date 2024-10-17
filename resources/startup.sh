#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

echo "                                     ./////,                    "
echo "                                 ./////==//////*                "
echo "                                ////.  ___   ////.              "
echo "                         ,**,. ////  ,////A,  */// ,**,.        "
echo "                    ,/////////////*  */////*  *////////////A    "
echo "                   ////'        \VA.   '|'   .///'       '///*  "
echo "                  *///  .*///*,         |         .*//*,   ///* "
echo "                  (///  (//////)**--_./////_----*//////)   ///) "
echo "                   V///   '°°°°      (/////)      °°°°'   ////  "
echo "                    V/////(////////\. '°°°' ./////////(///(/'   "
echo "                       'V/(/////////////////////////////V'      "

# shellcheck disable=SC1091
source /util.sh

if [[ $(nproc) -lt 4 ]]; then
  echo "WARNING: Your environment does not provide enough processing units for Sonatype Nexus. At least four cores are required.";
fi

# credentials for nexus-scripting tool
# NEXUS_PASSWORD cannot be set here because it needs to be fetched from
# different sources, depending on whether this is a restart or a first time start
export NEXUS_URL="http://localhost:8081/nexus"
export NEXUS_USER=${ADMINUSER}

# export ces admin group
CES_ADMIN_GROUP=$(doguctl config --global admin_group)
export CES_ADMIN_GROUP=${CES_ADMIN_GROUP}
TRUSTSTORE="${NEXUS_DATA_DIR}/truststore.jks"
MIGRATION_FILE="${NEXUS_DATA_DIR}/db/orient_backup.zip"
MIGRATION_HELPER_JAR="${NEXUS_DATA_DIR}/h2migration/migration_helper.jar"

### backup
if [ -e "${NEXUS_DATA_DIR}"/migration ]; then
  echo "moving old nexus data to migration volume"
  # remove flag so it won't be moved to migration volume
  rm "${NEXUS_DATA_DIR}/migration"
  # move all nexus 2 data to migration volume
  mv "${NEXUS_DATA_DIR}/*" /var/lib/migration/
  # also move hidden files
  mv "${NEXUS_DATA_DIR}/.[!.]*" /var/lib/migration/
fi

validateDoguLogLevel
echo "Rendering logging configuration..."
renderLoggingConfig

echo "Setting nexus.vmoptions..."
setNexusVmoptionsAndProperties

echo "Setting nexus.properties..."
setNexusProperties

# database migration from OrientDB to H2
if [ -e "${MIGRATION_FILE}" ]; then
  echo "Performing database migration from OrientDB to H2"

  # nexus cannot be running when database migration takes place
  # nexus process is not named nexus, but is the only running java process
  # echo "getting nexus pid"
  # sleep 1000
  # NEXUS_PID=$(ps | grep 'java'| grep -v "grep" | awk '{print $1}')
  # echo "${NEXUS_PID}"
  # echo "killing nexus"
  # kill -TERM ${NEXUS_PID} || true
  # echo "waiting for kill"
  # wait "${NEXUS_PID}" || true
  # echo "done waiting for kill"
  # NEXUS_CARP_PID=$(ps | grep 'nexus-carp'| grep -v "grep" | awk '{print $1}')
  # kill -TERM ${NEXUS_CARP_PID} || true
  # wait "${NEXUS_CARP_PID}" || true

  # download migration helper
  if [ ! -d "${NEXUS_DATA_DIR}/h2migration" ]; then
    mkdir "${NEXUS_DATA_DIR}/h2migration"
  fi
  curl -v --location --retry 3 -o "${MIGRATION_HELPER_JAR}" \
    "https://download.sonatype.com/nexus/nxrm3-migrator/nexus-db-migrator-$(printenv "NEXUS_DB_MIGRATOR_VERSION").jar"

  # run migration
  java -Xmx16G -Xms16G -XX:+UseG1GC -XX:MaxDirectMemorySize=28672M \
    -jar "${MIGRATION_HELPER_JAR}" --yes
    --migration_type=h2

  # move migration artifact to final location
  mv "nexus.mv.db" "${NEXUS_DATA_DIR}/db"
  echo "nexus.datastore.enabled=true" >>${NEXUS_DATA_DIR}/etc/nexus.properties

  # finally remove migration file from volume
  rm "${MIGRATION_FILE}"
  rmdir "${NEXUS_DATA_DIR}/h2migration"
fi

if [[ "$(doguctl config successfulInitialConfiguration)" != "true" ]]; then
  doguctl state installing

  # create truststore
  create_truststore.sh "${TRUSTSTORE}" >/dev/null

  echo "Starting Nexus..."
  startNexus

  echo "waiting for file ${NEXUS_DATA_DIR}/admin.password to appear"
  waitForFile "${NEXUS_DATA_DIR}/admin.password" 300 || {
    echo "${NEXUS_DATA_DIR}/admin.password did not appear, something is broken"
    exit 1
  }

  echo "Waiting for health endpoint..."
  waitForHealthEndpointAtFirstStart "${ADMINUSER}"

  echo "Configuring Nexus for first start..."
  configureNexusAtFirstStart

  # Install default docker registry if not prohibited by config key
  if "$(doguctl config --default true installDefaultDockerRegistry)" != "false"; then
    installDefaultDockerRegistry
  fi

  doguctl config successfulInitialConfiguration true
else
  echo "we are in else"
  # Remove last temporary admin after successful startup and also here to make sure that it is deleted even in restart loop.
  removeLastTemporaryAdminUser
  createTemporaryAdminUser

  echo "Starting Nexus..."
  startNexus

  echo "Waiting for health endpoint..."
  waitForHealthEndpointAtSubsequentStart "${ADMINUSER}"

  echo "Configuring Nexus for subsequent start..."
  configureNexusAtSubsequentStart

fi

echo "writing admin_group_last to local config"
doguctl config admin_group_last "${CES_ADMIN_GROUP}"

echo "importing HTTP/S proxy settings from registry"
NEXUS_PASSWORD="${ADMINPW}" \
  nexus-scripting execute --file-payload "${NEXUS_WORKDIR}/resources/nexusConfParameters.json" "${NEXUS_WORKDIR}/resources/proxyConfiguration.groovy"

echo "apply cleanup policy"
 NEXUS_PASSWORD="${ADMINPW}" \
nexus-scripting execute --file-payload "${NEXUS_WORKDIR}/resources/nexusCleanupPolicies.json" "${NEXUS_WORKDIR}/resources/nexusSetupCleanupPolicies.groovy"

echo "apply cleanup blobstore task"
 NEXUS_PASSWORD="${ADMINPW}" \
 nexus-scripting execute --file-payload "${NEXUS_WORKDIR}/resources/nexusCompactBlobstoreTask.json" "${NEXUS_WORKDIR}/resources/nexusSetupCompactBlobstoreTask.groovy"


echo "configuring carp server"
doguctl template /etc/carp/carp.yml.tpl "${NEXUS_DATA_DIR}/carp.yml"

echo "starting carp in background"
NEXUS_PASSWORD="${ADMINPW}" \
  nexus-carp -logtostderr=true "${NEXUS_DATA_DIR}/carp.yml" &
# shellcheck disable=SC2034
NEXUS_CARP_PID=$!

doguctl config -e admin_user "${ADMINUSER}"
doguctl config -e admin_pw "${ADMINPW}"

echo "starting claim tool"
/claim.sh "${ADMINUSER}" "${ADMINPW}"

doguctl state ready

trap terminateNexusAndNexusCarp SIGTERM

# Wait for nexus or nexus-carp to stop
# We use || true, otherwise the script would fail here because of 'set -o errexit'
wait -n || true
echo "A process failed, terminating dogu"
# Terminate the remaining process
terminateNexusAndNexusCarp
