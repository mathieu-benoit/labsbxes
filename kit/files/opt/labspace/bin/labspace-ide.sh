#!/bin/sh
# Startup hook (agent, every boot, background): code-server on :8085, opened on
# the lab's project directory (chosen by labspace-stage.sh).
#
# --auth none: the port is only reachable through the runtime's published-port
# binding, which lands on the host's loopback.
set -eu

PROJECT="$(cat /labspace/project-dir)"

exec code-server \
  --bind-addr 0.0.0.0:8085 \
  --auth none \
  --disable-update-check \
  "$PROJECT" \
  > /tmp/labspace-ide.log 2>&1
