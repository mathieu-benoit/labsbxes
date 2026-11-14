#!/bin/sh
# Startup hook (agent, every boot, background): code-server on :8085, opened on
# the content repo's project/ directory.
#
# --auth none: the port is only reachable through the runtime's published-port
# binding, which lands on the host's loopback.
set -eu

WS="${WORKSPACE_DIR:?WORKSPACE_DIR is not set}"

exec code-server \
  --bind-addr 0.0.0.0:8085 \
  --auth none \
  --disable-update-check \
  "$WS/project" \
  > /tmp/labspace-ide.log 2>&1
