# registry.cloudogu.com/official/nexus
FROM registry.cloudogu.com/official/java:8u212-1
LABEL maintainer="robert.auer@cloudogu.com" \
    NAME="official/nexus" \
    VERSION="3.19.1-1"

# The version of nexus to install
ENV NEXUS_VERSION=3.19.1-01 \
    TINI_VERSION=0.18.0 \
    NEXUS_CLAIM_VERSION=0.3.0 \
    NEXUS_CARP_VERSION=0.3.2 \
    NEXUS_SCRIPTING_VERSION=0.2.0 \
    NEXUS_REPOSITORY_R_PLUGIN_VERSION="1.0.4" \
    NEXUS_REPOSITORY_HELM_PLUGIN_VERSION="0.0.13" \
    SERVICE_TAGS=webapp \
    SERVICE_ADDITIONAL_SERVICES='[{"name": "docker-registry", "location": "v2", "pass": "nexus/repository/docker-registry/v2/"}]' \
    NEXUS_WORKDIR=/opt/sonatype/nexus \
    NEXUS_SERVER="http://localhost:8081/nexus"

RUN set -x \
  # add nexus user and group
  && addgroup -S -g 1000 nexus \
  && adduser -S -h /var/lib/nexus -s /bin/bash -G nexus -u 1000 nexus \
  # install tini
  && curl --fail --silent --location --retry 3 -o /bin/tini \
    https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static-amd64 \
  && chmod +x /bin/tini \
  # install nexus
  && mkdir -p ${NEXUS_WORKDIR} \
  && curl --fail --silent --location --retry 3 \
    https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz \
  | gunzip \
  | tar x -C /tmp nexus-${NEXUS_VERSION} \
  && mv /tmp/nexus-${NEXUS_VERSION}/* ${NEXUS_WORKDIR}/ \
  && mv /tmp/nexus-${NEXUS_VERSION}/.[!.]* ${NEXUS_WORKDIR}/ \
  && rmdir /tmp/nexus-${NEXUS_VERSION} \
  # install nexus-claim
  && curl --fail --silent --location --retry 3 \
    https://github.com/cloudogu/nexus-claim/releases/download/v${NEXUS_CLAIM_VERSION}/nexus-claim-${NEXUS_CLAIM_VERSION}.tar.gz \
  | gunzip \
  | tar x -C /usr/bin \
  && curl --fail --silent --location --retry 3 \
  https://github.com/cloudogu/nexus-scripting/releases/download/v${NEXUS_SCRIPTING_VERSION}/nexus-scripting-${NEXUS_SCRIPTING_VERSION}.tar.gz \
  | gunzip \
  | tar x -C /usr/bin \
  && curl --fail --silent --location --retry 3 \
  https://github.com/cloudogu/nexus-carp/releases/download/v${NEXUS_CARP_VERSION}/nexus-carp-${NEXUS_CARP_VERSION}.tar.gz \
  | gunzip \
  | tar x -C /usr/bin \
  && curl --fail --silent --location --retry 3 -o ${NEXUS_WORKDIR}/deploy/nexus-repository-r-${NEXUS_REPOSITORY_R_PLUGIN_VERSION}-bundle.kar \
  https://repo1.maven.org/maven2/org/sonatype/nexus/plugins/nexus-repository-r/${NEXUS_REPOSITORY_R_PLUGIN_VERSION}/nexus-repository-r-${NEXUS_REPOSITORY_R_PLUGIN_VERSION}-bundle.kar \
  && curl --fail --silent --location --retry 3 -o ${NEXUS_WORKDIR}/deploy/nexus-repository-helm-${NEXUS_REPOSITORY_HELM_PLUGIN_VERSION}-bundle.kar \
  https://repo1.maven.org/maven2/org/sonatype/nexus/plugins/nexus-repository-helm/${NEXUS_REPOSITORY_HELM_PLUGIN_VERSION}/nexus-repository-helm-${NEXUS_REPOSITORY_HELM_PLUGIN_VERSION}-bundle.kar \
  && chown -R nexus:nexus ${NEXUS_WORKDIR} \
  && chmod -R 770 ${NEXUS_WORKDIR}

COPY resources /

RUN chown -R nexus:nexus /etc/carp /startup.sh /claim.sh /opt/sonatype

VOLUME /var/lib/nexus

EXPOSE 8082

WORKDIR ${NEXUS_WORKDIR}

HEALTHCHECK CMD [ $(doguctl healthy jenkins; echo $?) == 0 ]

ENTRYPOINT [ "/bin/tini", "--" ]
CMD ["/pre-startup.sh"]
