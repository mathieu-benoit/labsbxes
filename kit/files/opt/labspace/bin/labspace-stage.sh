#!/bin/sh
# Startup hook (agent, every boot, foreground). Must be idempotent.
#
# The workspace mounted by `sbx run` is the content repo:
#
#   <workspace>/labspace/   labspace.yaml + markdown  -> the interface (left)
#   <workspace>/project/    files the learner edits   -> the IDE (right)
#
# Same layout as labspace-infra content repos, so existing content works as is.
set -eu

WS="${WORKSPACE_DIR:-}"
INSTRUCTIONS=/labspace/instructions
SUPPORT=/etc/labspace-support

if [ -z "$WS" ] || [ ! -f "$WS/labspace/labspace.yaml" ]; then
  echo "labspace: no labspace/labspace.yaml found in the workspace (${WS:-<none>})." >&2
  echo "labspace: run sbx from, or pass, a folder with a labspace/ and a project/ directory." >&2
  exit 1
fi

mkdir -p "$WS/project"

# Instructions: a snapshot by default, a live link while authoring.
rm -rf "$INSTRUCTIONS"
if [ "${LABSPACE_DEV_MODE:-false}" = "true" ]; then
  ln -s "$WS/labspace" "$INSTRUCTIONS"
else
  cp -r "$WS/labspace" "$INSTRUCTIONS"
fi

# Read by the interface's analytics service at boot. Analytics stay off: there
# is no Docker Desktop preference to inherit inside a sandbox.
LABSPACE_ID="$(sed -n 's/^[[:space:]]*id:[[:space:]]*//p' "$WS/labspace/labspace.yaml" | head -n 1 | tr -d "\"'")"
cat > "$SUPPORT/metadata/metadata.json" <<EOF
{
  "labspace_mode": "$([ "${LABSPACE_DEV_MODE:-false}" = "true" ] && echo dev || echo standard)",
  "labspace_id": "${LABSPACE_ID:-unknown}",
  "source_repo": "",
  "content_version": "",
  "infra_version": "sbx-kit-0.1.0",
  "sandbox_name": "${SANDBOX_NAME:-}",
  "uuids": { "dd": null, "hub": null },
  "analytics_enabled": false
}
EOF
