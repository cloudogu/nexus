#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# variables
# ADMUSR="admin"
# ADMDEFAULTPW="admin123"
# ADMINGROUP=$(doguctl config --global admin_group)
# DOMAIN=$(doguctl config --global domain)
# MAIL_ADDRESS=$(doguctl config -d "nexus@${DOMAIN}" --global mail_address)
# FQDN=$(doguctl config --global fqdn)
NEXUS_DATA_DIR=/var/lib/nexus
NEXUS_PID=0

# function set_random_admin_password {
#   ADMPW=$(doguctl random)
#   curl -s --retry 3 --retry-delay 10 -X POST -H "Content-Type: application/json" -d "{data:{userId:\"$ADMUSR\",newPassword:\"$ADMPW\"}}" --insecure 'http://127.0.0.1:8081/nexus/service/local/users_setpw' -u "$ADMUSR":"$ADMDEFAULTPW"
#   doguctl config -e "admin_password" "${ADMPW}"
#   echo "${ADMPW}"
# }
#
# function render_template(){
#   FILE="$1"
#   if [ ! -f "$FILE" ]; then
#     echo >&2 "could not find template $FILE"
#     exit 1
#   fi
#
#   # render template
#   eval "echo \"$(cat $FILE)\""
# }
#
# function setProxyConfiguration(){
#   NEXUS_CONFIGURATION=$(curl -s -H 'content-type:application/json' -H 'accept:application/json' 'http://127.0.0.1:8081/nexus/service/local/global_settings/current' -u "$ADMUSR":"$ADMPW")
#   # Write proxy settings if enabled in etcd
#   if [ "true" == "$(doguctl config --global proxy/enabled)" ]; then
#     if PROXYSERVER=$(doguctl config --global proxy/server) && PROXYPORT=$(doguctl config --global proxy/port); then
#       writeProxyCredentialsTo "${NEXUS_CONFIGURATION}"
#       if PROXYUSER=$(doguctl config --global proxy/username) && PROXYPASSWORD=$(doguctl config --global proxy/password); then
#         writeProxyAuthenticationCredentialsTo "${NEXUS_CONFIGURATION}"
#       else
#         echo "Proxy authentication credentials are incomplete or not existent."
#       fi
#       putNexusConfiguration
#     else
#       echo "Proxy server or port configuration missing in etcd."
#     fi
#   else
#     PROXYSERVER=""
#     PROXYPORT=0
#     PROXYUSER=""
#     PROXYPASSWORD=""
#     writeProxyCredentialsTo "${NEXUS_CONFIGURATION}"
#     writeProxyAuthenticationCredentialsTo "${NEXUS_CONFIGURATION}"
#     putNexusConfiguration
#   fi
# }
#
# function writeProxyCredentialsTo(){
#   NEXUS_CONFIGURATION=$(echo "$1" | jq ".data.remoteProxySettings.httpProxySettings+={\"proxyHostname\": \"${PROXYSERVER}\"}")
#   NEXUS_CONFIGURATION=$(echo "${NEXUS_CONFIGURATION}" | jq ".data.remoteProxySettings.httpProxySettings+={\"proxyPort\": ${PROXYPORT}}")
# }
#
# function writeProxyAuthenticationCredentialsTo(){
#   # Add proxy authentication credentials
#   NEXUS_CONFIGURATION=$(echo "$1" | jq ".data.remoteProxySettings.httpProxySettings.authentication+={\"username\": \"${PROXYUSER}\"}")
#   NEXUS_CONFIGURATION=$(echo "${NEXUS_CONFIGURATION}" | jq ".data.remoteProxySettings.httpProxySettings.authentication+={\"password\": \"${PROXYPASSWORD}\"}")
# }
#
# function putNexusConfiguration(){
#   curl -s --retry 3 --retry-delay 10 -H "Content-Type: application/json" -X PUT -d "${NEXUS_CONFIGURATION}" "http://127.0.0.1:8081/nexus/service/local/global_settings/current" -u "$ADMUSR":"$ADMPW"
# }

function configureNexus() {
  echo "Configuring Nexus..."
  if [[ -e /opt/sonatype/nexus/resources/nexusConfiguration.json ]]; then
    echo "Posting configuration script to Nexus..."
    curl --silent --insecure -X POST --no-buffer --user admin:admin123 --header 'Content-Type: application/json' --header 'Accept: application/json' -d @/opt/sonatype/nexus/resources/nexusConfiguration.json 'https://192.168.56.2/nexus/service/rest/v1/script'
    CONFIG_STATUS=$(curl --silent --head --no-buffer --insecure --user admin:admin123 https://192.168.56.2/nexus/service/rest/v1/script/nexusConfiguration)
    CONFIG_STATUS_CODE=$(echo "$CONFIG_STATUS"|head -n 1|cut -d$' ' -f2)
    if [[ ${CONFIG_STATUS_CODE} != 200 ]]; then
      echo "Nexus configuration script has not been posted successfully"
      exit 1
    else
       echo "Executing configuration script..."
       SCRIPT_EXECUTION=$(curl --silent --head --insecure --no-buffer -X POST --user admin:admin123 --header 'Content-Type: text/plain' --header 'Accept: application/json' 'https://192.168.56.2/nexus/service/rest/v1/script/nexusConfiguration/run')
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
  echo "Stopping Nexus..."
  kill ${NEXUS_PID}
  wait ${NEXUS_PID}
}

function startNexusAndWaitForHealth(){
  echo "Starting Nexus and waiting for healthy state..."
  ${NEXUS_WORKDIR}/bin/nexus run &
  NEXUS_PID=$!
  END=$((SECONDS+120))
  NEXUS_IS_HEALTHY=false
  while [ $SECONDS -lt $END ]; do
    CURL_HEALTH_STATUS=$(curl --silent --head --no-buffer --insecure --user admin:admin123 https://192.168.56.2/nexus/service/metrics/healthcheck)
    HEALTH_STATUS_CODE=$(echo "$CURL_HEALTH_STATUS"|head -n 1|cut -d$' ' -f2)
    if [[ ${HEALTH_STATUS_CODE} != 200 ]]; then
      sleep 5
    else
      echo "Nexus is healthy now"
      NEXUS_IS_HEALTHY=true
      break
    fi
  done
  if [[ ! $NEXUS_IS_HEALTHY ]]; then
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

startNexusAndWaitForHealth

configureNexus

stopNexus

doguctl state ready

echo "Running Nexus..."
${NEXUS_WORKDIR}/bin/nexus run

#
#

# START_NEXUS="java \
#   -server -Djava.net.preferIPv4Stack=true -Xms256m -Xmx1g \
#   -Djavax.net.ssl.trustStore=${TRUSTSTORE} \
# 	-Djavax.net.ssl.trustStorePassword=changeit \
#   -Dnexus-work=/var/lib/nexus -Dnexus-webapp-context-path=/nexus \
#   -cp conf/:$(echo lib/*.jar | sed -e "s/ /:/g") \
#   org.sonatype.nexus.bootstrap.Launcher ./conf/jetty.xml ./conf/jetty-requestlog.xml"
#
# if ! [ -d /var/lib/nexus/plugin-repository/nexus-cas-plugin-"${CAS_PLUGIN_VERSION}" ]; then
#       echo "No cas-plugin installed"
#
#       startNexusAndWaitForHealth
#
#       ADMPW=$(set_random_admin_password)
#
#       # add cas Plugin
#       cp -dR /opt/sonatype/nexus/resources/nexus-cas-plugin-"${CAS_PLUGIN_VERSION}"/ /var/lib/nexus/plugin-repository/
#       # add mailconfig
#       MAIL_CONFIGURATION=$(curl -s -H 'content-type:application/json' -H 'accept:application/json' 'http://127.0.0.1:8081/nexus/service/local/global_settings/current' -u "$ADMUSR":"$ADMPW" | jq ".data.smtpSettings+={\"host\": \"postfix\"}" | jq ".data.smtpSettings+={\"username\": \"\"}" | jq ".data.smtpSettings+={\"password\": \"\"}" | jq ".data.globalRestApiSettings+={\"baseUrl\": \"https://$FQDN/nexus/\"}" | jq ".data.smtpSettings+={\"systemEmailAddress\": \"${MAIL_ADDRESS}\"}" | jq ".data+={\"securityAnonymousAccessEnabled\": false}" | jq ".data+={\"securityRealms\": [\"XmlAuthenticatingRealm\",\"XmlAuthorizingRealm\",\"CasAuthenticatingRealm\"]}")
#       curl -s --retry 3 --retry-delay 10 -H "Content-Type: application/json" -X PUT -d "$MAIL_CONFIGURATION" "http://127.0.0.1:8081/nexus/service/local/global_settings/current" -u "$ADMUSR":"$ADMPW"
#       # disable new version info
#       curl -s -H "Content-Type: application/json" -X PUT -d "{data:{enabled:false}}" "http://127.0.0.1:8081/nexus/service/local/lvo_config" -u "$ADMUSR":"$ADMPW"
#       kill $!
# fi
#
# if  ! doguctl config -e "admin_password" > /dev/null ; then
#   startNexusAndWaitForHealth
#   set_random_admin_password
#   kill $!
# fi
#
# ADMPW=$(doguctl config -e "admin_password")
#
# startNexusAndWaitForHealth
# setProxyConfiguration
# kill $!
#
# echo "render_template"
# # update cas url
# render_template "/opt/sonatype/nexus/resources/cas-plugin.xml.tpl" > "/var/lib/nexus/conf/cas-plugin.xml"
#
# /configuration.sh "$ADMUSR" "$ADMPW" "$ADMINGROUP" &
# /claim.sh &
#
# doguctl state ready
# exec $START_NEXUS
