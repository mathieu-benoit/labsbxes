#!/bin/sh
# Startup hook (agent, every boot, background): the Labspace interface on :3031.
# Internal only: the gateway (labspace-gateway.sh) is what listens on :3030.
set -eu

cd /opt/labspace/interface

export PORT=3031
# The interface re-reads labspace.yaml and the markdown on every request.
if [ "${LABSPACE_DEV_MODE:-false}" = "true" ]; then
  export CONTENT_DEV_MODE=true
fi

exec /opt/labspace/bin/node src/index.js > /tmp/labspace-ui.log 2>&1
