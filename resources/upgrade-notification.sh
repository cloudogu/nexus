#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

version = "$(docker images registry.cloudogu.com/official/nexus --format \"{{.Tag}}\")"

echo "${version}"