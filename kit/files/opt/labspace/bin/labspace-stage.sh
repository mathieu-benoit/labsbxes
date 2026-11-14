#!/bin/sh
# Startup hook (agent, every boot, foreground). Must be idempotent.
#
# Where the lab content comes from, first match wins:
#
#   1. The workspace mounted by `sbx run` is a content repo (authoring, demos):
#        <workspace>/labspace/   labspace.yaml + markdown  -> the interface (left)
#        <workspace>/project/    files the learner edits   -> the IDE (right)
#   2. A content kit is composed in (`--kit <content kit>`), which carries the
#      same two folders under /opt/labspace/content. The instructions are read
#      from there; the project is copied once to ~/project, so the learner's
#      edits stay in the sandbox and survive a restart.
#   3. Neither: the built-in getting-started lab (/opt/labspace/default-content),
#      which explains the options. This never fails the boot: a sandbox with no
#      content must still show the user what to do next, not a dead port.
#
# Same layout as labspace-infra content repos, so existing content works as is.
set -eu

WS="${WORKSPACE_DIR:-}"
BAKED=/opt/labspace/content
BUILTIN=/opt/labspace/default-content
INSTRUCTIONS=/labspace/instructions
SUPPORT=/etc/labspace-support

if [ -n "$WS" ] && [ -f "$WS/labspace/labspace.yaml" ]; then
  SOURCE="workspace"
  SRC_LABSPACE="$WS/labspace"
  SRC_PROJECT=""
  PROJECT="$WS/project"
  mkdir -p "$PROJECT"
elif [ -f "$BAKED/labspace/labspace.yaml" ]; then
  SOURCE="content kit"
  SRC_LABSPACE="$BAKED/labspace"
  SRC_PROJECT="$BAKED/project"
  PROJECT="$HOME/project"
else
  SOURCE="built-in"
  SRC_LABSPACE="$BUILTIN/labspace"
  SRC_PROJECT="$BUILTIN/project"
  PROJECT="$HOME/project"
  echo "labspace: no lab content found (workspace: ${WS:-<none>}); serving the built-in getting-started lab."
fi

# A project that lives in the sandbox is seeded once, so the learner's edits
# survive a restart.
if [ -n "$SRC_PROJECT" ] && [ ! -d "$PROJECT" ]; then
  mkdir -p "$PROJECT"
  if [ -d "$SRC_PROJECT" ]; then
    cp -r "$SRC_PROJECT/." "$PROJECT/"
  fi
fi

# Tell the IDE hook which folder to open.
printf '%s\n' "$PROJECT" > /labspace/project-dir

# Instructions: a snapshot by default, a live link while authoring (only
# meaningful for workspace content, which is the thing being edited).
rm -rf "$INSTRUCTIONS"
if [ "${LABSPACE_DEV_MODE:-false}" = "true" ] && [ "$SOURCE" = "workspace" ]; then
  ln -s "$SRC_LABSPACE" "$INSTRUCTIONS"
else
  cp -r "$SRC_LABSPACE" "$INSTRUCTIONS"
fi

# The built-in lab names where it looked and which sandbox this is.
if [ "$SOURCE" = "built-in" ]; then
  esc() { printf '%s' "$1" | sed 's/[\\|&]/\\&/g'; }
  WS_SHOWN="${WS:-(no workspace was mounted)}"
  find "$INSTRUCTIONS" -name '*.md' -exec sed -i \
    -e "s|@@WORKSPACE@@|$(esc "$WS_SHOWN")|g" \
    -e "s|@@SANDBOX@@|$(esc "${SANDBOX_NAME:-<sandbox-name>}")|g" {} +
fi

# Read by the interface's analytics service at boot. Analytics stay off: there
# is no Docker Desktop preference to inherit inside a sandbox.
LABSPACE_ID="$(sed -n 's/^[[:space:]]*id:[[:space:]]*//p' "$SRC_LABSPACE/labspace.yaml" | head -n 1 | tr -d "\"'")"
cat > "$SUPPORT/metadata/metadata.json" <<EOF
{
  "labspace_mode": "$([ "${LABSPACE_DEV_MODE:-false}" = "true" ] && echo dev || echo standard)",
  "labspace_id": "${LABSPACE_ID:-unknown}",
  "source_repo": "",
  "content_version": "",
  "infra_version": "sbx-kit-0.1.0",
  "content_source": "$SOURCE",
  "sandbox_name": "${SANDBOX_NAME:-}",
  "uuids": { "dd": null, "hub": null },
  "analytics_enabled": false
}
EOF
