# registry.cloudogu.com/official/nexus
FROM registry.cloudogu.com/official/java:8u151-2
MAINTAINER Sebastian Sdorra <sebastian.sdorra@cloudogu.com>

# dockerfile based on https://registry.hub.docker.com/u/sonatype/nexus/dockerfile/

# The version of nexus to install
ENV TINI_VERSION=0.15.0 \
    NEXUS_VERSION=3.10.0-04 \
    NEXUS_CLAIM_VERSION=0.1.0 \
    CAS_PLUGIN_VERSION=1.2.2-SNAPSHOT \
    SERVICE_TAGS=webapp \
    NEXUS_WORKDIR=/opt/sonatype/nexus


RUN set -x \
  # add nexus user and group
  && addgroup -S -g 1000 nexus \
  && adduser -S -h /var/lib/nexus -s /bin/false -G nexus -u 1000 nexus \
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
  && rm -rf /tmp/nexus-${NEXUS_VERSION} \
  # install nexus-claim
  && curl --fail --silent --location --retry 3 \
    https://github.com/cloudogu/nexus-claim/releases/download/v${NEXUS_CLAIM_VERSION}/nexus-claim-${NEXUS_CLAIM_VERSION}.tar.gz \
  | gunzip \
  | tar x -C /usr/bin

COPY resources /

RUN chown -R nexus:nexus ${NEXUS_WORKDIR} \
  && chmod -R 777 ${NEXUS_WORKDIR}

USER nexus

VOLUME /var/lib/nexus

EXPOSE 8081

WORKDIR ${NEXUS_WORKDIR}

ENTRYPOINT [ "/bin/tini", "--" ]
CMD ["/startup.sh"]
