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
      --add-exports ch.qos.logback.classic/ch.qos.logback.classic.model.processor=ch.qos.logback.core
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
  nexus.datastore.enabled=true
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

  setupSecretFile

}

function setupSecretFile() {
  # See https://help.sonatype.com/en/re-encryption-in-nexus-repository.html
  # for further instructions
  SECRET_FILE="${NEXUS_DATA_DIR}/etc/nexus.secrets.json"
  if [[ -f "${SECRET_FILE}" ]] && [[ -f "${NEXUS_WORKDIR}/resources/nexus.secrets.json.tpl" ]]; then
    echo "Secret-File ${SECRET_FILE} already exists"
    echo "nexus.secrets.file=${SECRET_FILE}" >>${NEXUS_DATA_DIR}/etc/nexus.properties
    return
  fi

  echo "Creating new Security-File for Dynamic Encryption Key"

  # 01 Create the JSON Key File
  # ---------------------------

  SECRET_ID="nexus-dynamic-secret"
  SECRET_KEY="$(doguctl random)"
  # this might be "null" if we are on a multinode system
  doguctl config "secret_encryption/active" "${SECRET_ID}"

  # to activate match "active" with "id"
  doguctl config "secret_encryption/id" "${SECRET_ID}"
  doguctl config "secret_encryption/key" "${SECRET_KEY}"

  # create secret file via template
  doguctl template "${NEXUS_WORKDIR}/resources/nexus.secrets.json.tpl" "${SECRET_FILE}"

  echo " - Security-File created"

  # 02 Enable Re-Encryption
  # -----------------------

  # configure Nexus to use this newly created file
  if grep -Fxq "nexus.secrets.file=" "${NEXUS_DATA_DIR}/etc/nexus.properties"; then
    echo "Nexus properties already contains a nexus secret file."
    echo "Check ${NEXUS_DATA_DIR}/etc/nexus.properties"
    exit 1
  fi
  echo "nexus.secrets.file=${SECRET_FILE}" >>${NEXUS_DATA_DIR}/etc/nexus.properties

  echo " - Security-File set in nexus.properties"

  # 03 Create Re-encryption Task via API
  # ------------------------------------

  # enable encryption after start
  doguctl config "secret_encryption/start" "1"
  echo " - Scheduled API-Task after startup"
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

  # Enable re-encryption if set
#  if [ "$(doguctl config 'secret_encryption/start')" == "1" ]; then
    echo "Start Task for Re-Encryption"
    echo " - use $(doguctl config -global "fqdn") as fqdn"
    echo " - use $(doguctl config 'secret_encryption/id') as secretKeyId"

    curl -v --user "${ADMINUSER}:${ADMINPW}" \
      -X 'PUT' \
      "http://localhost:8081/nexus/service/rest/v1/secrets/encryption/re-encrypt" \
      -H 'accept: application/json' \
      -H 'Content-Type: application/json' \
      -H 'X-Nexus-UI: true' \
      -d '{ "secretKeyId": "nexus-dynamic-secret"}' \

    # deactivate for next startup
#    doguctl config -rm 'secret_encryption/start'
#  fi
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
  terminateNexus
  echo "Stopping nexus-carp"
  kill -TERM "$NEXUS_CARP_PID" || true
  wait "$NEXUS_CARP_PID" || true
  echo "Nexus shut down gracefully"
  exit 1
}

function terminateNexus() {
  echo "Stopping nexus"
  kill -TERM "$NEXUS_PID" || true
  wait "$NEXUS_PID" || true
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
      echo "${SCRIPT_LOG_PREFIX} ERROR: The loglevel configured in ${DEFAULT_LOGGING_KEY} is invalid."
      echo "${SCRIPT_LOG_PREFIX} ERROR: Fix the loglevel. Exiting now"
      exit 1
  fi

  return
}

# execution of sql function will only work when nexus process is not running, as it blocks the db
function sql() {
  SQL="${1}"
  psql -d "postgresql://$(doguctl config -e sa-postgresql/username):$(doguctl config -e sa-postgresql/password)@postgresql:5432/$(doguctl config -e sa-postgresql/database)" -c "${SQL}"
}

function createPasswordHash() {
  local PW="${1}"
  java -jar "/shiro-tools-hasher.jar" -a SHA-512 -i 1024 -f shiro1 "${PW}"
}

function createTemporaryAdminUser() {
  local hashed
  hashed="$(createPasswordHash "${ADMINPW}")"
  echo "Creating admin user '${ADMINUSER}'"
  sql "INSERT INTO security_user (status, id, first_name, last_name, email, password) VALUES ('active', '${ADMINUSER}', '${ADMINUSER}', '${ADMINUSER}', 'dogu-tool-admin@cloudogu.com', '${hashed}');"
  sql "INSERT INTO user_role_mapping (user_id, user_lo, source, roles) VALUES ('${ADMINUSER}', '${ADMINUSER}', 'default', '[\"nx-admin\"]');"
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
  sql "DELETE FROM user_role_mapping WHERE user_id='${userid}';"
  sql "DELETE FROM security_user WHERE id='${userid}';"
  doguctl config --rm last_tmp_admin
  doguctl config --rm last_tmp_admin_pw
}

# Nexus has a default session timeout of 30 minutes
# it is removed by setting the time to 0ms
# If it is not removed, the ui crashes after 30 minutes of inactivity
function removeSessionTimeout() {
  # manipulate the database entry directly, until nexus adds this feature to the capabilities api
  sql "UPDATE capability_storage_item
     SET properties = jsonb_set(properties, '{sessionTimeout}', '\"0\"', true)
   WHERE type = 'rapture.settings';"
}

function setPostgresEnvVariables() {
  user=$(doguctl config -e sa-postgresql/username)
  pw=$(doguctl config -e sa-postgresql/password)
  db=$(doguctl config -e sa-postgresql/database)
  cons=$(doguctl config database/maxConnections)

  export NEXUS_DATASTORE_NEXUS_JDBCURL="jdbc:postgresql://postgresql:5432/${db}?user=${user}&password=${pw}&currentSchema=public"
  export NEXUS_DATASTORE_NEXUS_USERNAME="${user}"
  export NEXUS_DATASTORE_NEXUS_PASSWORD="${pw}"
  export NEXUS_DATASTORE_NEXUS_ADVANCED="maximumPoolSize=${cons}"
}