#!/bin/sh
# Install hook (root, once per sandbox).
#
# What is left of the labspace-infra `configurator`: the pieces that must exist
# before the interface and the IDE start. Content staging happens at every boot
# in labspace-stage.sh, because the workspace is only known to the runtime.
set -eu

SUPPORT=/etc/labspace-support
mkdir -p "$SUPPORT/private-key" "$SUPPORT/public-key" "$SUPPORT/socket" "$SUPPORT/metadata" /labspace

# ES256 keypair. The interface signs the "run this command" request with the
# private key, the IDE extension verifies it with the public key. Both now live
# in the same sandbox, so this is defence in depth against anything else that
# can reach the unix socket, not a trust boundary between containers.
/opt/labspace/bin/node -e '
const { generateKeyPairSync } = require("node:crypto");
const fs = require("node:fs");
const { privateKey, publicKey } = generateKeyPairSync("ec", { namedCurve: "prime256v1" });
fs.writeFileSync("/etc/labspace-support/private-key/labspace.key",
  privateKey.export({ type: "pkcs8", format: "pem" }), { mode: 0o600 });
fs.writeFileSync("/etc/labspace-support/public-key/labspace.pem",
  publicKey.export({ type: "spki", format: "pem" }), { mode: 0o644 });
'

chown -R 1000:1000 "$SUPPORT" /labspace
