#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# variables
ADMINUSER="admin"
export ADMINDEFAULTPASSWORD="admin123"
NEXUS_DATA_DIR=/var/lib/nexus
# credentials for nexus-scripting tool
export NEXUS_URL="http://localhost:8081/nexus"
export NEXUS_USER=${ADMINUSER}
export NEXUS_PASSWORD=${ADMINDEFAULTPASSWORD}
# create random admin password
NEWADMINPASSWORD=$(doguctl random)
export NEWADMINPASSWORD=${NEWADMINPASSWORD}

# export ces admin group
CES_ADMIN_GROUP=$(doguctl config --global admin_group)
export CES_ADMIN_GROUP=${CES_ADMIN_GROUP}
TRUSTSTORE="${NEXUS_DATA_DIR}/truststore.jks"

### declaration of functions
function setNexusVmoptionsAndProperties() {
  cat <<EOF > "${NEXUS_WORKDIR}/bin/nexus.vmoptions"
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

  mkdir -p ${NEXUS_DATA_DIR}/etc
  cat <<EOF > ${NEXUS_DATA_DIR}/etc/nexus.properties
  nexus-context-path=/nexus
EOF
}

function configureNexusAtFirstStart() {
  if [ -f "${NEXUS_WORKDIR}/resources/nexusConfigurationFirstStart.groovy" ] && [ -f "${NEXUS_WORKDIR}/resources/nexusConfParameters.json.tpl" ]; then
    doguctl template "${NEXUS_WORKDIR}/resources/nexusConfParameters.json.tpl" "${NEXUS_WORKDIR}/resources/nexusConfParameters.json"
    nexus-scripting execute --file-payload "${NEXUS_WORKDIR}/resources/nexusConfParameters.json" "${NEXUS_WORKDIR}/resources/nexusConfigurationFirstStart.groovy"
    doguctl config -e "admin_password" "${NEWADMINPASSWORD}"
  else
    echo "Configuration files do not exist"
    exit 1
  fi
}

function configureNexusAtSubsequentStart() {
  if [ -f "${NEXUS_WORKDIR}/resources/nexusConfigurationSubsequentStart.groovy" ] && [ -f "${NEXUS_WORKDIR}/resources/nexusConfParameters.json.tpl" ]; then
    doguctl template "${NEXUS_WORKDIR}/resources/nexusConfParameters.json.tpl" "${NEXUS_WORKDIR}/resources/nexusConfParameters.json"
    nexus-scripting execute --file-payload "${NEXUS_WORKDIR}/resources/nexusConfParameters.json" "${NEXUS_WORKDIR}/resources/nexusConfigurationSubsequentStart.groovy"
  else
    echo "Configuration files do not exist"
    exit 1
  fi
}

function startNexusAndWaitForHealth() {
  "${NEXUS_WORKDIR}/bin/nexus" run &
  NEXUS_PID=$!
  echo "wait until nexus passes all health checks"
  export HTTP_BASIC_AUTH_USERNAME=$1
  export HTTP_BASIC_AUTH_PASSWORD=$2
  if ! doguctl wait-for-http --timeout 300 --method GET http://localhost:8081/nexus/service/metrics/healthcheck; then
    echo "timeout reached while waiting for nexus to get healthy"
    exit 1
  fi
}

function exportNexusPassword() {
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


### beginning of startup
echo "Setting nexus.vmoptions and properties..."
setNexusVmoptionsAndProperties

if [ "$(doguctl config successfulInitialConfiguration)" != "true" ]; then
  doguctl state installing

  # create truststore
  create_truststore.sh "${TRUSTSTORE}" > /dev/null

  echo "Starting Nexus and waiting for healthy state..."
  startNexusAndWaitForHealth ${ADMINUSER} ${ADMINDEFAULTPASSWORD}

  echo "Configuring Nexus..."
  configureNexusAtFirstStart

  exportNexusPassword

  export NEXUS_SERVER="http://localhost:8081/nexus"
  nexus-claim plan -i /defaultDockerRegistry.hcl -o "-" | nexus-claim apply -i "-"

  doguctl config successfulInitialConfiguration true
else

  exportNexusPassword

  echo "Starting Nexus and waiting for healthy state..."
  startNexusAndWaitForHealth ${ADMINUSER} "${NEXUS_PASSWORD}"

  echo "Configuring Nexus..."
  configureNexusAtSubsequentStart

fi

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
