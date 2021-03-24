# registry.cloudogu.com/official/nexus
FROM registry.cloudogu.com/official/java:8u252-1
LABEL maintainer="robert.auer@cloudogu.com" \
    NAME="official/nexus" \
    VERSION="3.28.1-4"

# The version of nexus to install
ENV NEXUS_VERSION=3.30.0-01 \
    TINI_VERSION=0.19.0 \
    NEXUS_CLAIM_VERSION=1.0.0 \
    NEXUS_CARP_VERSION=1.2.0 \
    NEXUS_SCRIPTING_VERSION=0.2.0 \
    SERVICE_TAGS=webapp \
    SERVICE_ADDITIONAL_SERVICES='[{"name": "docker-registry", "location": "v2", "pass": "nexus/repository/docker-registry/v2/"}]' \
    NEXUS_WORKDIR=/opt/sonatype/nexus \
    NEXUS_SERVER="http://localhost:8081/nexus" \
    SHA256_TINI="c5b0666b4cb676901f90dfcb37106783c5fe2077b04590973b885950611b30ee" \
    SHA256_NEXUS_TAR="6b186ec3514dbadf89a92d560b1c9098fd3caa1d2d5e7f5402fcf61a3d6418fb" \
    SHA256_NEXUS_CLAIM="a34608ac7b516d6bc91f8a157bea286919c14e5fb5ecc76fc15edccb35adec42" \
    SHA256_NEXUS_SCRIPTING="60c7f3d8a0c97b1d90d954ebad9dc07dbeb7927934b618c874b2e72295cafb48" \
    SHA256_NEXUS_CARP="29f8a0dba8519183cef73a69a32a59759114ec97c6a1ef9e4d11b899eacd4854"

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
