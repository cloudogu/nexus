# registry.cloudogu.com/official/nexus
FROM registry.cloudogu.com/official/java:8u151-3
LABEL maintainer="robert.auer@cloudogu.com"

# The version of nexus to install
ENV NEXUS_VERSION=3.11.0-01 \
    TINI_VERSION=0.15.0 \
    NEXUS_CLAIM_VERSION=0.2.0 \
    NEXUS_CARP_VERSION=0.2.1 \
    NEXUS_SCRIPTING_VERSION=0.1.1 \
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
  && chown -R nexus:nexus ${NEXUS_WORKDIR} \
  && chmod -R 770 ${NEXUS_WORKDIR}

COPY --chown=nexus resources /

USER nexus

VOLUME /var/lib/nexus

EXPOSE 8082

WORKDIR ${NEXUS_WORKDIR}

ENTRYPOINT [ "/bin/tini", "--" ]
CMD ["/startup.sh"]
