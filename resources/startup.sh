#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# variables
ADMINUSER="admin"
ADMINDEFAULTPASSWORD="admin123"
FQDN=$(doguctl config --global fqdn)
NEXUS_DATA_DIR=/var/lib/nexus
NEXUS_PID=0

function setNexusVmoptionsAndProperties() {
  cat <<EOF > ${NEXUS_WORKDIR}/bin/nexus.vmoptions
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

function configureNexus() {
  if [[ -e /opt/sonatype/nexus/resources/nexusConfiguration.groovy ]]; then
    nexus-scripting execute --file-payload /opt/sonatype/nexus/resources/nexusConfiguration.groovy http://localhost:8081/nexus/service/rest/v1/script
  else
    echo "Configuration script does not exist"
  fi
}

function stopNexus() {
  kill ${NEXUS_PID}
  wait ${NEXUS_PID}
  #TODO: Add timeout
}

function startNexusAndWaitForHealth(){
  ${NEXUS_WORKDIR}/bin/nexus run &
  NEXUS_PID=$!
  END=$((SECONDS+120))
  NEXUS_IS_HEALTHY=false
  while [ $SECONDS -lt $END ]; do
    echo "checking nexus..."
    CURL_HEALTH_STATUS=$(curl -v --head --user ${ADMINUSER}:${ADMINDEFAULTPASSWORD} http://localhost:8081/nexus/service/metrics/healthcheck)|| true
    HEALTH_STATUS_CODE=$(echo "$CURL_HEALTH_STATUS"|head -n 1|cut -d$' ' -f2)
    echo "HEALTH_STATUS_CODE = $HEALTH_STATUS_CODE"
    if [[ ${HEALTH_STATUS_CODE} != 200 ]]; then
      sleep 1
    else
      echo "Nexus is healthy now"
      NEXUS_IS_HEALTHY=true
      break
    fi
  done
  if [[ "${NEXUS_IS_HEALTHY}" == "false" ]]; then
    echo "Nexus did not reach healthy state in 120 seconds"
    exit 1
  fi
}

echo "configuring carp server"
doguctl template /etc/carp/carp-tpl.yml ${NEXUS_DATA_DIR}/carp.yml

echo "start carp in background"
carp -logtostderr ${NEXUS_DATA_DIR}/carp.yml &

if [ "$(doguctl config successfulInitialConfiguration)" != "true" ]; then
  doguctl state installing

  # create truststore
  TRUSTSTORE="${NEXUS_DATA_DIR}/truststore.jks"
  create_truststore.sh "${TRUSTSTORE}" > /dev/null

  echo "Setting nexus.vmoptions and properties..."
  setNexusVmoptionsAndProperties

  echo "Starting Nexus and waiting for healthy state..."
  startNexusAndWaitForHealth

  echo "Configuring Nexus..."
  configureNexus

  echo "Stopping Nexus..."
  stopNexus

  doguctl config successfulInitialConfiguration true
fi

doguctl state ready

echo "Running Nexus..."
${NEXUS_WORKDIR}/bin/nexus run
