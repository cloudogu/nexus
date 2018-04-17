#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# variables
ADMINUSER="admin"
export ADMINDEFAULTPASSWORD="admin123"
NEXUS_DATA_DIR=/var/lib/nexus
NEXUS_PID=0
# credentials for nexus-scripting tool
export NEXUS_URL="http://localhost:8081/nexus"
export NEXUS_USER=${ADMINUSER}
export NEXUS_PASSWORD=${ADMINDEFAULTPASSWORD}
# create and save random admin password
export NEWADMINPASSWORD=$(doguctl random)
doguctl config -e "admin_password" "${NEWADMINPASSWORD}"

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
  if [ -f /opt/sonatype/nexus/resources/nexusConfiguration.groovy ] && [ -f /opt/sonatype/nexus/resources/nexusConfParameters.json.tpl ]; then
    doguctl template /opt/sonatype/nexus/resources/nexusConfParameters.json.tpl /opt/sonatype/nexus/resources/nexusConfParameters.json
    nexus-scripting execute --file-payload /opt/sonatype/nexus/resources/nexusConfParameters.json /opt/sonatype/nexus/resources/nexusConfiguration.groovy
    # password has been changed while executing script
    export NEXUS_PASSWORD=$(doguctl config -e admin_password)
  else
    echo "Configuration files do not exist"
    exit 1
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
    CURL_HEALTH_STATUS=$(curl --silent --head --user $1:$2 http://localhost:8081/nexus/service/metrics/healthcheck)|| true
    HEALTH_STATUS_CODE=$(echo "$CURL_HEALTH_STATUS"|head -n 1|cut -d$' ' -f2)
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



if [ "$(doguctl config successfulInitialConfiguration)" != "true" ]; then
  doguctl state installing

  # create truststore
  TRUSTSTORE="${NEXUS_DATA_DIR}/truststore.jks"
  create_truststore.sh "${TRUSTSTORE}" > /dev/null

  echo "Setting nexus.vmoptions and properties..."
  setNexusVmoptionsAndProperties

  echo "Starting Nexus and waiting for healthy state..."
  startNexusAndWaitForHealth ${ADMINUSER} ${ADMINDEFAULTPASSWORD}

  echo "Configuring Nexus..."
  configureNexus

  echo "Stopping Nexus..."
  stopNexus

  doguctl config successfulInitialConfiguration true
fi

doguctl state ready

echo "Running Nexus..."
#${NEXUS_WORKDIR}/bin/nexus run &
# start nexus before nexus-carp until nexus-carp is able to wait
startNexusAndWaitForHealth ${ADMINUSER} ${NEXUS_PASSWORD}
echo "configuring carp server"
doguctl template /etc/carp/carp-tpl.yml ${NEXUS_DATA_DIR}/carp.yml

echo "starting carp"
nexus-carp -logtostderr ${NEXUS_DATA_DIR}/carp.yml
