#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# variables
ADMINUSER="dogu-tool-admin-$(doguctl random)"
ADMINPW="$(doguctl random)"
NEXUS_DATA_DIR=/var/lib/nexus
LOGBACK_CONF_DIR="${NEXUS_WORKDIR}/etc/logback"
LOGBACK_FILE="${LOGBACK_CONF_DIR}/logback.xml"
LOGBACK_TEMPLATE_FILE=/logback.xml.tpl
LOGBACK_OVERRIDE_DIR="${NEXUS_DATA_DIR}/etc/logback"
LOGBACK_OVERRIDE_FILE="${LOGBACK_OVERRIDE_DIR}/logback-overrides.xml"
LOGBACK_OVERRIDE_TEMPLATE_FILE=/logback-overrides.xml.tpl
DEFAULT_LOGGING_KEY="logging/root"
SCRIPT_LOG_PREFIX="Log level mapping:"

function setNexusVmoptionsAndProperties() {
  local VM_OPTIONS_FILE
  VM_OPTIONS_FILE="${NEXUS_WORKDIR}/bin/nexus.vmoptions"

  cat <<EOF >"$VM_OPTIONS_FILE"
      -XX:MaxDirectMemorySize=2G
      -XX:+UnlockDiagnosticVMOptions
      -XX:+LogVMOutput
      -XX:LogFile=${NEXUS_DATA_DIR}/log/jvm.log
      -XX:-OmitStackTraceInFastThrow
      -Dlog4j2.formatMsgNoLookups=true
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
      --add-reads=java.xml=java.logging
      --add-exports=java.base/org.apache.karaf.specs.locator=java.xml,ALL-UNNAMED
      --patch-module=java.base=./lib/endorsed/org.apache.karaf.specs.locator-4.3.9.jar
      --patch-module=java.xml=./lib/endorsed/org.apache.karaf.specs.java.xml-4.3.9.jar
      --add-opens=java.base/java.security=ALL-UNNAMED
      --add-opens=java.base/java.net=ALL-UNNAMED
      --add-opens=java.base/java.lang=ALL-UNNAMED
      --add-opens=java.base/java.util=ALL-UNNAMED
      --add-opens=java.naming/javax.naming.spi=ALL-UNNAMED
      --add-opens=java.rmi/sun.rmi.transport.tcp=ALL-UNNAMED
      --add-exports=java.base/sun.net.www.protocol.http=ALL-UNNAMED
      --add-exports=java.base/sun.net.www.protocol.https=ALL-UNNAMED
      --add-exports=java.base/sun.net.www.protocol.jar=ALL-UNNAMED
      --add-exports=jdk.xml.dom/org.w3c.dom.html=ALL-UNNAMED
      --add-exports=jdk.naming.rmi/com.sun.jndi.url.rmi=ALL-UNNAMED
      --add-exports=java.security.sasl/com.sun.security.sasl=ALL-UNNAMED
EOF

  echo "Setting memory limits..."
  if [[ "$(doguctl config "container_config/memory_limit" -d "empty")" != "empty" ]]; then
    # Retrieve configurable java limits from etcd, valid default values exist
    MEMORY_LIMIT_MAX_PERCENTAGE=$(doguctl config "container_config/java_max_ram_percentage")
    MEMORY_LIMIT_MIN_PERCENTAGE=$(doguctl config "container_config/java_min_ram_percentage")

    echo "Setting memory limits..."
    echo "-XX:MaxRAMPercentage=${MEMORY_LIMIT_MAX_PERCENTAGE}" >>"${VM_OPTIONS_FILE}"
    echo "-XX:MinRAMPercentage=${MEMORY_LIMIT_MIN_PERCENTAGE}" >>"${VM_OPTIONS_FILE}"
  else
    echo "-Xms1200M" >>"${VM_OPTIONS_FILE}"
    echo "-Xmx1200M" >>"${VM_OPTIONS_FILE}"
  fi

  cat "${VM_OPTIONS_FILE}"
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
  echo "enabling groovy scripting"
  echo "nexus.scripts.allowCreation=true" >>${NEXUS_DATA_DIR}/etc/nexus.properties
}

function configureNexusAtFirstStart() {
  if [ -f "${NEXUS_WORKDIR}/resources/nexusConfigurationFirstStart.groovy" ] && [ -f "${NEXUS_WORKDIR}/resources/nexusConfParameters.json.tpl" ]; then
    ADMINUSER="admin"
    export NEXUS_USER="${ADMINUSER}"

    local nexusPassword
    nexusPassword="$(<${NEXUS_DATA_DIR}/admin.password)"

    echo "Rendering nexusConfParameters template"
    ADMINDEFAULTPASSWORD="${nexusPassword}" \
      NEWADMINPASSWORD="${ADMINPW}" \
      doguctl template "${NEXUS_WORKDIR}/resources/nexusConfParameters.json.tpl" \
      "${NEXUS_WORKDIR}/resources/nexusConfParameters.json"

    echo "Rendering cleanupPolicies template"
    ADMINDEFAULTPASSWORD="${nexusPassword}" \
      NEWADMINPASSWORD="${ADMINPW}" \
      doguctl template "${NEXUS_WORKDIR}/resources/nexusCleanupPolicies.json.tpl" \
      "${NEXUS_WORKDIR}/resources/nexusCleanupPolicies.json"

    echo "Rendering compactBlobstore template"
    ADMINDEFAULTPASSWORD="${nexusPassword}" \
      NEWADMINPASSWORD="${ADMINPW}" \
      doguctl template "${NEXUS_WORKDIR}/resources/nexusCompactBlobstoreTask.json.tpl" \
      "${NEXUS_WORKDIR}/resources/nexusCompactBlobstoreTask.json"

    echo "Executing nexusConfigurationFirstStart script"

    NEXUS_PASSWORD="${nexusPassword}" \
      nexus-scripting execute \
      --file-payload "${NEXUS_WORKDIR}/resources/nexusConfParameters.json" \
      "${NEXUS_WORKDIR}/resources/nexusConfigurationFirstStart.groovy"
  else
    echo "Configuration files do not exist"
    exit 1
  fi
}

function configureNexusAtSubsequentStart() {
  if [ -f "${NEXUS_WORKDIR}/resources/nexusConfigurationSubsequentStart.groovy" ] && [ -f "${NEXUS_WORKDIR}/resources/nexusConfParameters.json.tpl" ]; then
    echo "Getting current admin password"

    echo "Rendering nexusConfParameters template"
    doguctl template "${NEXUS_WORKDIR}/resources/nexusConfParameters.json.tpl" \
      "${NEXUS_WORKDIR}/resources/nexusConfParameters.json"

    echo "Rendering cleanupPolicies template"
    doguctl template "${NEXUS_WORKDIR}/resources/nexusCleanupPolicies.json.tpl" \
      "${NEXUS_WORKDIR}/resources/nexusCleanupPolicies.json"

    echo "Rendering compactBlobstore template"
    doguctl template "${NEXUS_WORKDIR}/resources/nexusCompactBlobstoreTask.json.tpl" \
      "${NEXUS_WORKDIR}/resources/nexusCompactBlobstoreTask.json"

    echo "Executing nexusConfigurationSubsequentStart script"
    NEXUS_PASSWORD="${ADMINPW}" \
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

function waitForHealthEndpoint() {
  local username=$1
  local password=$2
  local attempt_counter=0
  local max_attempts=300

  echo "Waiting until Nexus health endpoint is available (max. ${max_attempts} seconds)..."

  until curl --user "${username}":"${password}" --silent --output /dev/null http://localhost:8081/nexus/service/metrics/healthcheck; do
    if [ ${attempt_counter} -eq ${max_attempts} ]; then
      echo "Max attempts reached; exiting..."
      exit 1
    fi
    attempt_counter=$((attempt_counter + 1))
    sleep 1
  done

  local health_endpoint_response
  local unhealthy_checks
  health_endpoint_response=$(curl --user "${username}":"${password}" --silent http://localhost:8081/nexus/service/metrics/healthcheck)
  unhealthy_checks=$(echo "${health_endpoint_response}" | jq -c 'to_entries[] | select(.value.healthy==false) | [.key, .value.message]')
  if [[ ${unhealthy_checks} != "" ]]; then
    echo "WARNING! Some of the Sonatype Nexus health checks have failed:"
    echo "${unhealthy_checks}"
  else
    echo "All Sonatype Nexus health checks have succeeded"
  fi
}

function waitForHealthEndpointAtFirstStart() {
  waitForHealthEndpoint "$1" "$(<${NEXUS_DATA_DIR}/admin.password)"
}

function waitForHealthEndpointAtSubsequentStart() {
  waitForHealthEndpoint "$1" "${ADMINPW}"
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

  NEXUS_PASSWORD="${ADMINPW}" \
    nexus-claim plan -i /defaultDockerRegistry.hcl -o "-" | \
    NEXUS_PASSWORD="${ADMINPW}" \
      nexus-claim apply -i "-"
}

function renderLoggingConfig() {
  [[ -d "${LOGBACK_CONF_DIR}" ]] || mkdir -p "${LOGBACK_CONF_DIR}"

  doguctl template "${LOGBACK_TEMPLATE_FILE}" "${LOGBACK_FILE}"

  [[ -d "${LOGBACK_OVERRIDE_DIR}" ]] || mkdir -p "${LOGBACK_OVERRIDE_DIR}"
  doguctl template "${LOGBACK_OVERRIDE_TEMPLATE_FILE}" "${LOGBACK_OVERRIDE_FILE}"
}

function validateDoguLogLevel() {
  echo "${SCRIPT_LOG_PREFIX} Validate root log level"

  validateExitCode=0
  doguctl validate "${DEFAULT_LOGGING_KEY}" || validateExitCode=$?

  if [[ ${validateExitCode} -ne 0 ]]; then
    echo "${SCRIPT_LOG_PREFIX} WARNING: The loglevel configured in ${DEFAULT_LOGGING_KEY} is invalid."
    echo "${SCRIPT_LOG_PREFIX} WARNING: Removing misconfigured value."
    doguctl config --rm "${DEFAULT_LOGGING_KEY}"
  fi

  return
}

function sql() {
  SQL="${1}"
  java -cp /opt/sonatype/nexus/system/com/h2database/h2/*/h2*.jar org.h2.tools.Shell -url "jdbc:h2:file:/var/lib/nexus/db" -user "admin" -password "password" -sql "${SQL}" > dev/null
}

function createPasswordHash() {
  local PW="${1}"
  java -jar "/shiro-tools-hasher.jar" -a SHA-512 -i 1024 -f shiro1 "${PW}"
}

function createTemporaryAdminUser() {
  local hashed
  hashed="$(createPasswordHash "${ADMINPW}")"
  echo "Creating admin user '${ADMINUSER}'"
  sql "INSERT INTO user (status, id, firstName, lastName, email, password) VALUES ('active', '${ADMINUSER}', '${ADMINUSER}', '${ADMINUSER}', 'dogu-tool-admin@cloudogu.com', '${hashed}')"
  sql "INSERT INTO user_role_mapping (userId, source, roles) VALUES ('${ADMINUSER}', 'default', 'nx-admin')"
  doguctl config last_tmp_admin "${ADMINUSER}"
  doguctl config last_tmp_admin_pw "${ADMINPW}"
}

function removeLastTemporaryAdminUser() {
  local none='<none>'
  local userid
  userid="$(doguctl config --default "${none}" last_tmp_admin)"
  if [ "${userid}" = "${none}" ]; then
    return
  fi

  echo "Removing last tmp admin user '${userid}'"
  sql "DELETE FROM user_role_mapping WHERE userId='${userid}'"
  sql "DELETE FROM user WHERE id='${userid}'"
  doguctl config --rm last_tmp_admin
  doguctl config --rm last_tmp_admin_pw
}
