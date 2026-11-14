#!/bin/sh
# Startup hook (agent, every boot, background): the single published port, :3030.
set -eu

exec /opt/labspace/bin/node /opt/labspace/bin/labspace-gateway.mjs > /tmp/labspace-gateway.log 2>&1
