#!/bin/bash

# older installation of redmine exposed the core plugins to the
# plugin volume, these exposed plugin could be old and must be
# removed.

set -o errexit
set -o nounset
set -o pipefail
