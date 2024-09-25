#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

echo "Put ces-server certificate in system store"
su nexus -c "doguctl config --global certificate/server.crt" > "/etc/ssl/certs/server.crt"
exec su nexus -c "/startup.sh"