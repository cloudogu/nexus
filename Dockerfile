FROM registry.cloudogu.com/official/java:17.0.18-4 AS builder
LABEL maintainer="hello@cloudogu.com" \
    NAME="official/nexus" \
    VERSION="3.82.0-5"

WORKDIR /build

# The version of nexus to install
ENV NEXUS_VERSION=3.82.0-08 \
    TINI_VERSION=0.19.0 \
    NEXUS_CLAIM_VERSION=1.1.4 \
    NEXUS_CARP_VERSION=1.6.1 \
    NEXUS_SCRIPTING_VERSION=0.3.2 \
    SHIRO_VERSION=1.11.0 \
    NEXUS_BUILD_DIR=/build/opt/sonatype/nexus \
    BUILD_BIN_DIR=/build/usr/bin \
    SHA256_TINI="c5b0666b4cb676901f90dfcb37106783c5fe2077b04590973b885950611b30ee" \
    SHA256_NEXUS_TAR="697eacdda855e6f81a861465b7febaf190da12c4aa298268805b87d894302d35" \
    SHA256_NEXUS_CLAIM="59664145d8ea0dc95bfcd9c3a74861a30ba4266361ac1dbb2eb2bb847ea87963" \
    SHA256_NEXUS_SCRIPTING="8dbe923534e14357b5adb0748d29f912109a57dbd983ea8c783a4037764cc955" \
    SHA256_NEXUS_CARP="17c042711fecd8d4e20b5d8ec9b642508e7fe2255d304b86074a9c2eb09cb056"

RUN set -o errexit \
  && set -o nounset \
  && set -o pipefail \
  && apk update \
  && apk upgrade \
  && apk add curl \
  && mkdir -p ${BUILD_BIN_DIR} \
  # install tini
  && curl --fail --silent --location --retry 3 -o ${BUILD_BIN_DIR}/tini \
    https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static-amd64 \
  && echo "${SHA256_TINI} *${BUILD_BIN_DIR}/tini" |sha256sum -c - \
  && chmod +x ${BUILD_BIN_DIR}/tini \
  # install nexus
  && mkdir -p ${NEXUS_BUILD_DIR} \
  && curl --fail --silent --location --retry 3 -o nexus.tar.gz \
    https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-linux-x86_64.tar.gz \
  && echo "${SHA256_NEXUS_TAR} *nexus.tar.gz" |sha256sum -c - \
  && tar -xf nexus.tar.gz -C /tmp nexus-${NEXUS_VERSION} \
  && mv /tmp/nexus-${NEXUS_VERSION}/* ${NEXUS_BUILD_DIR}/ \
  # install nexus-claim
  && curl --fail --silent --location --retry 3 -o nexus-claim.tar.gz \
    https://github.com/cloudogu/nexus-claim/releases/download/v${NEXUS_CLAIM_VERSION}/nexus-claim-${NEXUS_CLAIM_VERSION}.tar.gz \
  && echo "${SHA256_NEXUS_CLAIM} *nexus-claim.tar.gz" |sha256sum -c - \
  && tar -xf nexus-claim.tar.gz -C ${BUILD_BIN_DIR} \
  && curl --fail --silent --location --retry 3 -o nexus-scripting.tar.gz \
    https://github.com/cloudogu/nexus-scripting/releases/download/v${NEXUS_SCRIPTING_VERSION}/nexus-scripting-${NEXUS_SCRIPTING_VERSION}.tar.gz \
  && echo "${SHA256_NEXUS_SCRIPTING} *nexus-scripting.tar.gz" |sha256sum -c - \
  && tar -xf nexus-scripting.tar.gz -C ${BUILD_BIN_DIR} \
  && curl --fail --silent --location --retry 3 -o nexus-carp.tar.gz \
    https://github.com/cloudogu/nexus-carp/releases/download/v${NEXUS_CARP_VERSION}/nexus-carp-${NEXUS_CARP_VERSION}.tar.gz \
  && echo "${SHA256_NEXUS_CARP} *nexus-carp.tar.gz" | sha256sum -c - \
  && tar -xf nexus-carp.tar.gz -C ${BUILD_BIN_DIR} \
  && apk add maven \
  && mvn dependency:get -DgroupId=org.apache.shiro.tools -DartifactId=shiro-tools-hasher -Dclassifier=cli -Dversion=${SHIRO_VERSION} \
  && cp /root/.m2/repository/org/apache/shiro/tools/shiro-tools-hasher/${SHIRO_VERSION}/shiro-tools-hasher-${SHIRO_VERSION}-cli.jar /build/shiro-tools-hasher.jar

FROM registry.cloudogu.com/official/java:17.0.18-3

ENV SERVICE_TAGS=webapp \
    SERVICE_ADDITIONAL_SERVICES='[{"name": "docker-registry", "port": 8082, "location": "v2", "pass": "nexus/repository/docker-registry/v2/"}]' \
    NEXUS_WORKDIR=/opt/sonatype/nexus \
    NEXUS_SERVER="http://localhost:8081/nexus" \
    DOGU_RESOURCE_DIR="/" \
    # Nexus uses their own jdk by default
    INSTALL4J_JAVA_HOME_OVERRIDE=/usr/lib/jvm/java-17-openjdk

COPY --from=builder /build /
COPY resources /

WORKDIR ${NEXUS_WORKDIR}

RUN set -o errexit \
  && set -o nounset \
  && set -o pipefail \
  && apk update \
  && apk upgrade \
  && apk add --no-cache curl \
  # use psql14 client until the postgresql database gets updated to newest version \
  # ignore the warning in the logs until then
  # && apk add postgresql14-client \
  # temporarily add old repo
  && echo "https://dl-cdn.alpinelinux.org/alpine/v3.20/main" > /tmp/old-repos \
  && echo "https://dl-cdn.alpinelinux.org/alpine/v3.20/community" >> /tmp/old-repos \
  \
  && apk add --no-cache --repositories-file=/tmp/old-repos postgresql14-client \
  \
  # cleanup
  && rm -f /tmp/old-repos \
  # add nexus user and group
  && addgroup -S -g 1000 nexus \
  && adduser -S -h /var/lib/nexus -s /bin/bash -G nexus -u 1000 nexus \
  && chown -R nexus:nexus ${NEXUS_WORKDIR} \
  && chmod -R 770 ${NEXUS_WORKDIR} \
  && chown -R nexus:nexus /etc/carp /startup.sh /claim.sh /opt/sonatype /*.tpl /create-sa.sh /util.sh /nexus_api.sh /remove-sa.sh /shiro-tools-hasher.jar

VOLUME /var/lib/nexus

EXPOSE 8082

HEALTHCHECK CMD doguctl healthy nexus || exit 1

ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD ["/pre-startup.sh"]
