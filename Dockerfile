# registry.cloudogu.com/official/nexus
FROM registry.cloudogu.com/official/java:8u242-2
LABEL maintainer="robert.auer@cloudogu.com" \
    NAME="official/nexus" \
    VERSION="3.23.0-4"

# The version of nexus to install
ENV NEXUS_VERSION=3.23.0-03 \
    TINI_VERSION=0.18.0 \
    NEXUS_CLAIM_VERSION=1.0.0 \
    NEXUS_CARP_VERSION=1.0.0 \
    NEXUS_SCRIPTING_VERSION=0.2.0 \
    NEXUS_REPOSITORY_R_PLUGIN_VERSION="1.0.5" \
    NEXUS_REPOSITORY_HELM_PLUGIN_VERSION="0.0.13" \
    SERVICE_TAGS=webapp \
    SERVICE_ADDITIONAL_SERVICES='[{"name": "docker-registry", "location": "v2", "pass": "nexus/repository/docker-registry/v2/"}]' \
    NEXUS_WORKDIR=/opt/sonatype/nexus \
    NEXUS_SERVER="http://localhost:8081/nexus" \
    SHA256_TINI="eadb9d6e2dc960655481d78a92d2c8bc021861045987ccd3e27c7eae5af0cf33" \
    SHA256_NEXUS_TAR="673492fc4f281df31c4f023aac1cc0e423ded6703b5a9c6a2b455265312ee8cb" \
    SHA256_NEXUS_CLAIM="a34608ac7b516d6bc91f8a157bea286919c14e5fb5ecc76fc15edccb35adec42" \
    SHA256_NEXUS_SCRIPTING="60c7f3d8a0c97b1d90d954ebad9dc07dbeb7927934b618c874b2e72295cafb48" \
    SHA256_NEXUS_CARP="b5e20e607ea3c5a1f463b2bdac8c96a29f3213a571fad185877ca274466b576b" \
    SHA256_NEXUS_R="8a13c4327b346743b0fbee533871d20719510c7c2d88ecd74574ca636e085372" \
    SHA256_NEXUS_HELM="1ed0e77b8cdff52ad6b27eb297bcfcf64c2fed7c0cd1462bd8223bd1faf7e56f" 

RUN set -x \
  # add nexus user and group
  && addgroup -S -g 1000 nexus \
  && adduser -S -h /var/lib/nexus -s /bin/bash -G nexus -u 1000 nexus \
  # install tini
  && curl --fail --silent --location --retry 3 -o /bin/tini \
    https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static-amd64 \
  && echo "${SHA256_TINI} */bin/tini" |sha256sum -c - \
  && chmod +x /bin/tini \
  # install nexus
  && mkdir -p ${NEXUS_WORKDIR} \
  && curl --fail --silent --location --retry 3 -o nexus.tar.gz \
    https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz \
  && echo "${SHA256_NEXUS_TAR} *nexus.tar.gz" |sha256sum -c - \  
  && tar -xf nexus.tar.gz -C /tmp nexus-${NEXUS_VERSION} \
  && rm nexus.tar.gz \
  && mv /tmp/nexus-${NEXUS_VERSION}/* ${NEXUS_WORKDIR}/ \
  && mv /tmp/nexus-${NEXUS_VERSION}/.[!.]* ${NEXUS_WORKDIR}/ \
  && rmdir /tmp/nexus-${NEXUS_VERSION} \
  # install nexus-claim
  && curl --fail --silent --location --retry 3 -o nexus-claim.tar.gz \
    https://github.com/cloudogu/nexus-claim/releases/download/v${NEXUS_CLAIM_VERSION}/nexus-claim-${NEXUS_CLAIM_VERSION}.tar.gz \
  && echo "${SHA256_NEXUS_CLAIM} *nexus-claim.tar.gz" |sha256sum -c - \
  && tar -xf nexus-claim.tar.gz -C /usr/bin \
  && rm nexus-claim.tar.gz \
  && curl --fail --silent --location --retry 3 -o nexus-scripting.tar.gz \
  https://github.com/cloudogu/nexus-scripting/releases/download/v${NEXUS_SCRIPTING_VERSION}/nexus-scripting-${NEXUS_SCRIPTING_VERSION}.tar.gz \
  && echo "${SHA256_NEXUS_SCRIPTING} *nexus-scripting.tar.gz" |sha256sum -c - \
  && tar -xf nexus-scripting.tar.gz -C /usr/bin \
  && rm nexus-scripting.tar.gz \
  && curl --fail --silent --location --retry 3 -o nexus-carp.tar.gz \
  https://github.com/cloudogu/nexus-carp/releases/download/v${NEXUS_CARP_VERSION}/nexus-carp-${NEXUS_CARP_VERSION}.tar.gz \
  && echo "${SHA256_NEXUS_CARP} *nexus-carp.tar.gz" | sha256sum -c - \
  && tar -xf nexus-carp.tar.gz -C /usr/bin \
  && rm nexus-carp.tar.gz \
  && curl --fail --silent --location --retry 3 -o ${NEXUS_WORKDIR}/deploy/nexus-repository-r-${NEXUS_REPOSITORY_R_PLUGIN_VERSION}-bundle.kar \
  https://repo1.maven.org/maven2/org/sonatype/nexus/plugins/nexus-repository-r/${NEXUS_REPOSITORY_R_PLUGIN_VERSION}/nexus-repository-r-${NEXUS_REPOSITORY_R_PLUGIN_VERSION}-bundle.kar \
  && echo "${SHA256_NEXUS_R} *${NEXUS_WORKDIR}/deploy/nexus-repository-r-${NEXUS_REPOSITORY_R_PLUGIN_VERSION}-bundle.kar" |sha256sum -c - \
  && curl --fail --silent --location --retry 3 -o ${NEXUS_WORKDIR}/deploy/nexus-repository-helm-${NEXUS_REPOSITORY_HELM_PLUGIN_VERSION}-bundle.kar \
  https://repo1.maven.org/maven2/org/sonatype/nexus/plugins/nexus-repository-helm/${NEXUS_REPOSITORY_HELM_PLUGIN_VERSION}/nexus-repository-helm-${NEXUS_REPOSITORY_HELM_PLUGIN_VERSION}-bundle.kar \
  && echo "${SHA256_NEXUS_HELM} *${NEXUS_WORKDIR}/deploy/nexus-repository-helm-${NEXUS_REPOSITORY_HELM_PLUGIN_VERSION}-bundle.kar" |sha256sum -c - \
  && chown -R nexus:nexus ${NEXUS_WORKDIR} \
  && chmod -R 770 ${NEXUS_WORKDIR}

COPY resources /

RUN chown -R nexus:nexus /etc/carp /startup.sh /claim.sh /opt/sonatype /*.tpl

VOLUME /var/lib/nexus

EXPOSE 8082

WORKDIR ${NEXUS_WORKDIR}

HEALTHCHECK CMD doguctl healthy nexus || exit 1

ENTRYPOINT [ "/bin/tini", "--" ]
CMD ["/pre-startup.sh"]
