#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC1091
source /util.sh

if [[ $(nproc) -lt 4 ]]; then
  echo "WARNING: Your environment does not provide enough processing units for Sonatype Nexus. At least four cores are required.";
fi

# variables
ADMINUSER="dogu-tool-admin-$(doguctl random)"
ADMINPW="$(doguctl random)"
NEXUS_DATA_DIR=/var/lib/nexus

# credentials for nexus-scripting tool
# NEXUS_PASSWORD cannot be set here because it needs to be fetched from
# different sources, depending on whether this is a restart or a first time start
export NEXUS_URL="http://localhost:8081/nexus"
export NEXUS_USER=${ADMINUSER}

# export ces admin group
CES_ADMIN_GROUP=$(doguctl config --global admin_group)
export CES_ADMIN_GROUP=${CES_ADMIN_GROUP}
TRUSTSTORE="${NEXUS_DATA_DIR}/truststore.jks"

### backup
if [ -e "${NEXUS_DATA_DIR}"/migration ]; then
  echo "moving old nexus data to migration volume"
  # remove flag so it won't be moved to migration volume
  rm ${NEXUS_DATA_DIR}/migration
  # move all nexus 2 data to migration volume
  mv ${NEXUS_DATA_DIR}/* /var/lib/migration/
  # also move hidden files
  mv ${NEXUS_DATA_DIR}/.[!.]* /var/lib/migration/
fi

validateDoguLogLevel
echo "Rendering logging configuration..."
renderLoggingConfig

echo "Setting nexus.vmoptions..."
setNexusVmoptionsAndProperties

echo "Setting nexus.properties..."
setNexusProperties

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

  # Install default docker registry if not prohibited by etcd key
  if "$(doguctl config --default true installDefaultDockerRegistry)" != "false"; then
    installDefaultDockerRegistry
  fi

  doguctl config successfulInitialConfiguration true

else
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

echo "writing admin_group_last to etcd"
doguctl config admin_group_last "${CES_ADMIN_GROUP}"

echo "importing HTTP/S proxy settings from registry"
NEXUS_PASSWORD="${ADMINPW}" \
  nexus-scripting execute --file-payload "${NEXUS_WORKDIR}/resources/nexusConfParameters.json" "${NEXUS_WORKDIR}/resources/proxyConfiguration.groovy"

echo "configuring carp server"
doguctl template /etc/carp/carp.yml.tpl "${NEXUS_DATA_DIR}/carp.yml"

echo "starting carp in background"
NEXUS_PASSWORD="${ADMINPW}" \
  nexus-carp -logtostderr "${NEXUS_DATA_DIR}/carp.yml" &
# shellcheck disable=SC2034
NEXUS_CARP_PID=$!

echo "starting claim tool"
/claim.sh "${ADMINPW}"

doguctl state ready

trap terminateNexusAndNexusCarp SIGTERM

# Wait for nexus or nexus-carp to stop
# We use || true, otherwise the script would fail here because of 'set -o errexit'
wait -n || true
echo "A process failed, terminating dogu"
# Terminate the remaining process
terminateNexusAndNexusCarp
