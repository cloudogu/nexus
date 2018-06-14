#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

version = $(sudo docker images registry.cloudogu.com/official/nexus --format "{{.Tag}}")

echo $version
