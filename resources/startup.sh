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

function configureNexus() {
  if [[ -e /opt/sonatype/nexus/resources/nexusConfiguration.json ]]; then
    echo "Posting configuration script to Nexus..."
    curl --silent --insecure -X POST --no-buffer --user ${ADMINUSER}:${ADMINDEFAULTPASSWORD} --header 'Content-Type: application/json' --header 'Accept: application/json' -d @/opt/sonatype/nexus/resources/nexusConfiguration.json "https://${FQDN}/nexus/service/rest/v1/script"
    CONFIG_STATUS=$(curl --silent --head --no-buffer --insecure --user ${ADMINUSER}:${ADMINDEFAULTPASSWORD} https://${FQDN}/nexus/service/rest/v1/script/nexusConfiguration)
    CONFIG_STATUS_CODE=$(echo "$CONFIG_STATUS"|head -n 1|cut -d$' ' -f2)
    if [[ ${CONFIG_STATUS_CODE} != 200 ]]; then
      echo "Nexus configuration script has not been posted successfully"
      exit 1
    else
       echo "Executing configuration script..."
       SCRIPT_EXECUTION=$(curl --silent --head --insecure --no-buffer -X POST --user ${ADMINUSER}:${ADMINDEFAULTPASSWORD} --header 'Content-Type: text/plain' --header 'Accept: application/json' "https://${FQDN}/nexus/service/rest/v1/script/nexusConfiguration/run")
       SCRIPT_STATUS_CODE=$(echo "${SCRIPT_EXECUTION}"|head -n 1|cut -d$' ' -f2)
       if [[ ${SCRIPT_STATUS_CODE} != 200 ]]; then
         echo "Configuration script has not been executed successfully"
         exit 1
       else
         echo "Removing /opt/sonatype/nexus/resources/nexusConfiguration.json"
         rm /opt/sonatype/nexus/resources/nexusConfiguration.json
       fi
    fi
  else
    echo "Configuration file doesn't exist"
  fi
}

function stopNexus() {
  kill ${NEXUS_PID}
  wait ${NEXUS_PID}
}

function startNexusAndWaitForHealth(){
  ${NEXUS_WORKDIR}/bin/nexus run &
  NEXUS_PID=$!
  END=$((SECONDS+120))
  NEXUS_IS_HEALTHY=false
  while [ $SECONDS -lt $END ]; do
    CURL_HEALTH_STATUS=$(curl --silent --head --no-buffer --insecure --user ${ADMINUSER}:${ADMINDEFAULTPASSWORD} https://${FQDN}/nexus/service/metrics/healthcheck)
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

doguctl state installing

# create truststore
TRUSTSTORE="${NEXUS_DATA_DIR}/truststore.jks"
create_truststore.sh "${TRUSTSTORE}" > /dev/null

echo "Setting nexus.vmoptions..."
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

echo "configuration carp server"
doguctl template /etc/carp/carp-tpl.yml ${NEXUS_DATA_DIR}/carp.yml

echo "start carp in background"
carp -logtostderr ${NEXUS_DATA_DIR}/carp.yml &

echo "Starting Nexus and waiting for healthy state..."
startNexusAndWaitForHealth

echo "Configuring Nexus..."
configureNexus

echo "Stopping Nexus..."
stopNexus

doguctl state ready

echo "Running Nexus..."
${NEXUS_WORKDIR}/bin/nexus run
