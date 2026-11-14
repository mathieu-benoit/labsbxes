#!/bin/sh
# Startup hook (agent, every boot, background): code-server on 127.0.0.1:8085,
# opened on the content repo's project/ directory.
#
# --auth none: it listens on loopback only. The one published port is the
# gateway's, whose binding lands on the host's loopback, and it serves the IDE
# under /ide/.
set -eu

WS="${WORKSPACE_DIR:?WORKSPACE_DIR is not set}"

exec code-server \
  --bind-addr 127.0.0.1:8085 \
  --auth none \
  --disable-update-check \
  "$WS/project" \
  > /tmp/labspace-ide.log 2>&1
