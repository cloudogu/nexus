#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

if [[ $(nproc) -lt 4 ]]; then
  echo "ERROR: Your environment does not provide enough processing units for Sonatype Nexus. At least four cores are required.";
  doguctl state "ErrorNotEnoughProcessingUnits"
  sleep 300;
  exit 1;
fi

# variables
ADMINUSER="admin"
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

### declaration of functions
function setNexusVmoptionsAndProperties() {
  cat <<EOF >"${NEXUS_WORKDIR}/bin/nexus.vmoptions"
  -Xms1200M
  -Xmx1200M
  -XX:MaxDirectMemorySize=2G
  -XX:+UnlockDiagnosticVMOptions
  -XX:+UnsyncloadClass
  -XX:+LogVMOutput
  -XX:LogFile=${NEXUS_DATA_DIR}/log/jvm.log
  -XX:-OmitStackTraceInFastThrow
  -Djava.net.preferIPv4Stack=true
  -Dkaraf.home=.
  -Dkaraf.base=.
  -Dkaraf.etc=etc/karaf
  -Djava.util.logging.config.file=etc/karaf/java.util.logging.properties
  -Dkaraf.data=${NEXUS_DATA_DIR}
  -Djava.io.tmpdir=${NEXUS_DATA_DIR}/tmp
  -Dkaraf.startLocalConsole=false
  -Djavax.net.ssl.trustStore=${TRUSTSTORE}
  -Djavax.net.ssl.trustStorePassword=changeit
  -Djava.net.preferIPv4Stack=true
EOF
}

function setNexusProperties() {
  echo "Creating properties file..."
  mkdir -p ${NEXUS_DATA_DIR}/etc
  cat <<EOF >${NEXUS_DATA_DIR}/etc/nexus.properties
  nexus-context-path=/nexus
EOF

  echo "Checking if repository sandboxing should be enabled..."
  if doguctl config nexus.repository.sandbox.enable >/dev/null; then
    sandboxEnable=$(doguctl config nexus.repository.sandbox.enable)
    echo "Setting repository sandboxing to ${sandboxEnable}"
    echo "nexus.repository.sandbox.enable=${sandboxEnable}" >>${NEXUS_DATA_DIR}/etc/nexus.properties
  else
    echo "Not enabling repository sandboxing"
  fi
}

function configureNexusAtFirstStart() {
  if [ -f "${NEXUS_WORKDIR}/resources/nexusConfigurationFirstStart.groovy" ] && [ -f "${NEXUS_WORKDIR}/resources/nexusConfParameters.json.tpl" ]; then
    local nexusPassword
    nexusPassword="$(<${NEXUS_DATA_DIR}/admin.password)"

    local newAdminPassword
    newAdminPassword="$(doguctl random)"

    echo "Rendering nexusConfParameters template"
    ADMINDEFAULTPASSWORD="${nexusPassword}" \
      NEWADMINPASSWORD="${newAdminPassword}" \
      doguctl template "${NEXUS_WORKDIR}/resources/nexusConfParameters.json.tpl" \
      "${NEXUS_WORKDIR}/resources/nexusConfParameters.json"

    echo "Executing nexusConfigurationFirstStart script"

    NEXUS_PASSWORD="${nexusPassword}" \
      nexus-scripting execute \
      --file-payload "${NEXUS_WORKDIR}/resources/nexusConfParameters.json" \
      "${NEXUS_WORKDIR}/resources/nexusConfigurationFirstStart.groovy"
    doguctl config -e "admin_password" "${newAdminPassword}"
  else
    echo "Configuration files do not exist"
    exit 1
  fi
}

function configureNexusAtSubsequentStart() {
  if [ -f "${NEXUS_WORKDIR}/resources/nexusConfigurationSubsequentStart.groovy" ] && [ -f "${NEXUS_WORKDIR}/resources/nexusConfParameters.json.tpl" ]; then
    echo "Rendering nexusConfParameters template"
    doguctl template "${NEXUS_WORKDIR}/resources/nexusConfParameters.json.tpl" \
      "${NEXUS_WORKDIR}/resources/nexusConfParameters.json"

    # uses NEXUS_PASSWORD set by exportNexusPasswordFromEtcd
    echo "Executing nexusConfigurationSubsequentStart script"
    nexus-scripting execute \
      --file-payload "${NEXUS_WORKDIR}/resources/nexusConfParameters.json" \
      "${NEXUS_WORKDIR}/resources/nexusConfigurationSubsequentStart.groovy"
  else
    echo "Configuration files do not exist"
    exit 1
  fi
}

function waitForFile() {
  local file="$1"
  local wait_seconds="${2}"

  until test $((wait_seconds--)) -eq 0 -o -f "$file"; do sleep 1; done

  test -f "$file"
}

function startNexus() {
  "${NEXUS_WORKDIR}/bin/nexus" run &
  NEXUS_PID=$!
}

function doHealthCheck() {
  echo "wait until nexus passes all health checks"

  export HTTP_BASIC_AUTH_USERNAME=$1
  export HTTP_BASIC_AUTH_PASSWORD=$2

  if ! doguctl wait-for-http --timeout 300 --method GET http://localhost:8081/nexus/service/metrics/healthcheck; then
    echo "timeout reached while waiting for nexus to get healthy"
    HEALTH_INFORMATION=$(curl -s -u "${HTTP_BASIC_AUTH_USERNAME}":"${HTTP_BASIC_AUTH_PASSWORD}" http://localhost:8081/nexus/service/metrics/healthcheck)
    echo "Nexus Health information: ${HEALTH_INFORMATION}"
    exit 1
  else
    HEALTH_INFORMATION=$(curl -s -u "${HTTP_BASIC_AUTH_USERNAME}":"${HTTP_BASIC_AUTH_PASSWORD}" http://localhost:8081/nexus/service/metrics/healthcheck)
    echo "Nexus is healthy: ${HEALTH_INFORMATION}"
  fi
}

function waitForHealthCheck() {
  doHealthCheck "$1" "$(<${NEXUS_DATA_DIR}/admin.password)"
}

function waitForHealthCheckAtSubsequentStart() {
  doHealthCheck "$1" "$(doguctl config -e admin_password)"
}

function exportNexusPasswordFromEtcd() {
  echo "Getting current admin password"
  NEXUS_PASSWORD=$(doguctl config -e admin_password)
  export NEXUS_PASSWORD=${NEXUS_PASSWORD}
}

function terminateNexusAndNexusCarp() {
  echo "kill nexus"
  kill -TERM "$NEXUS_PID" || true
  wait "$NEXUS_PID" || true
  echo "kill nexus-carp"
  kill -TERM "$NEXUS_CARP_PID" || true
  wait "$NEXUS_CARP_PID" || true
  echo "Nexus shut down gracefully"
  exit 1
}

function installDefaultDockerRegistry() {
  echo "Installing default docker registry"
  export NEXUS_SERVER="http://localhost:8081/nexus"
  nexus-claim plan -i /defaultDockerRegistry.hcl -o "-" | nexus-claim apply -i "-"
}

### beginning of startup
echo "Setting nexus.vmoptions..."
setNexusVmoptionsAndProperties

echo "Setting nexus.properties..."
setNexusProperties

if [ "$(doguctl config successfulInitialConfiguration)" != "true" ]; then
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

  echo "Waiting for healthy state..."
  waitForHealthCheck ${ADMINUSER}

  echo "Configuring Nexus for first start..."
  configureNexusAtFirstStart

  echo "Exporting nexus password..."
  exportNexusPasswordFromEtcd

  # Install default docker registry if not prohibited by etcd key
  if "$(doguctl config --default true installDefaultDockerRegistry)" != "false"; then
    installDefaultDockerRegistry
  fi

  doguctl config successfulInitialConfiguration true

else

  # needs to be called before configureNexusAtSubsequentStart because it sets
  # NEXUS_PASSWORD env var
  echo "Exporting nexus password..."
  exportNexusPasswordFromEtcd

  echo "Starting Nexus..."
  startNexus

  echo "Waiting for healthy state..."
  waitForHealthCheckAtSubsequentStart ${ADMINUSER}

  echo "Configuring Nexus for subsequent start..."
  configureNexusAtSubsequentStart

fi

echo "writing admin_group_last to etcd"
doguctl config admin_group_last ${CES_ADMIN_GROUP}

echo "importing HTTP/S proxy settings from registry"
nexus-scripting execute --file-payload "${NEXUS_WORKDIR}/resources/nexusConfParameters.json" "${NEXUS_WORKDIR}/resources/proxyConfiguration.groovy"

echo "configuring carp server"
doguctl template /etc/carp/carp.yml.tpl ${NEXUS_DATA_DIR}/carp.yml

echo "starting carp in background"
nexus-carp -logtostderr ${NEXUS_DATA_DIR}/carp.yml &
NEXUS_CARP_PID=$!

echo "starting claim tool"
/claim.sh

doguctl state ready

trap terminateNexusAndNexusCarp SIGTERM

# Wait for nexus or nexus-carp to stop
# We use || true, otherwise the script would fail here because of 'set -o errexit'
wait -n || true
echo "A process failed, terminating dogu"
# Terminate the remaining process
terminateNexusAndNexusCarp
