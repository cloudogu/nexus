FROM registry.cloudogu.com/official/java:17.0.13-1 as builder
LABEL maintainer="hello@cloudogu.com" \
    NAME="official/nexus" \
    VERSION="3.75.0-3"

WORKDIR /build

# The version of nexus to install
ENV NEXUS_VERSION=3.75.0-06 \
    TINI_VERSION=0.19.0 \
    NEXUS_CLAIM_VERSION=1.1.1 \
    NEXUS_CARP_VERSION=1.4.1 \
    NEXUS_SCRIPTING_VERSION=0.2.0 \
    SHIRO_VERSION=1.11.0 \
    NEXUS_BUILD_DIR=/build/opt/sonatype/nexus \
    BUILD_BIN_DIR=/build/usr/bin \
    SHA256_TINI="c5b0666b4cb676901f90dfcb37106783c5fe2077b04590973b885950611b30ee" \
    SHA256_NEXUS_TAR="b2727c697bc98cf7ec566ec929090db0d5508d6eff428f201b6b41b6f9128ccf" \
    SHA256_NEXUS_CLAIM="74b0f9d752855a14533e829e658cb619fc2832d845860af2e0ddbf0cdd47a785" \
    SHA256_NEXUS_SCRIPTING="60c7f3d8a0c97b1d90d954ebad9dc07dbeb7927934b618c874b2e72295cafb48" \
    SHA256_NEXUS_CARP="db742df8f4c672d1aaa049efa097756d1f9b86e050331a01406cb97e11c41485"

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
    https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz \
  && echo "${SHA256_NEXUS_TAR} *nexus.tar.gz" |sha256sum -c - \
  && tar -xf nexus.tar.gz -C /tmp nexus-${NEXUS_VERSION} \
  && mv /tmp/nexus-${NEXUS_VERSION}/* ${NEXUS_BUILD_DIR}/ \
  && mv /tmp/nexus-${NEXUS_VERSION}/.[!.]* ${NEXUS_BUILD_DIR}/ \
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

FROM registry.cloudogu.com/official/java:17.0.13-1

ENV SERVICE_TAGS=webapp \
    SERVICE_ADDITIONAL_SERVICES='[{"name": "docker-registry", "port": 8082, "location": "v2", "pass": "nexus/repository/docker-registry/v2/"}]' \
    NEXUS_WORKDIR=/opt/sonatype/nexus \
    NEXUS_SERVER="http://localhost:8081/nexus"

COPY --from=builder /build /
COPY resources /

WORKDIR ${NEXUS_WORKDIR}

RUN set -o errexit \
  && set -o nounset \
  && set -o pipefail \
  && apk update \
  && apk upgrade \
  && apk add --no-cache curl \
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
