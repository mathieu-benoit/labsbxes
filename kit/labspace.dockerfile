# syntax=docker/dockerfile:1.7
#
# Labspace overlay: everything the lab needs, as files that land on the shell
# workload. Mirrors the sbx-kits-contrib code-server kit (build-time install,
# staged into `FROM scratch`), and reuses the images the labspace-infra repo
# already publishes instead of copying their source.

# Build stage only: same distribution as the runtime workload. The built-in
# `shell` agent is the docker.io/sbx/shell kit (Debian 13, Docker, git, jq,
# python, go; NO Node), pinned here by the digest this was developed against.
ARG BASE_IMAGE=docker.io/sbx/shell@sha256:89ed5d63def6bfb2373d408e3ab6ad55aa5c010f884a182a78299fcf85ea42d1

# Published by labspace-infra (docker-bake.hcl), pinned to a release by tag and
# index digest so a kit version always carries the same interface. To move to
# a new labspace-infra release, update both lines together:
#   docker buildx imagetools inspect dockersamples/labspace-interface:<tag> --format '{{.Manifest.Digest}}'
ARG INTERFACE_IMAGE=dockersamples/labspace-interface:v0.33.0@sha256:a9a7c4d23ed0c08585f6eef619684f2cd50465eca145d4d4a9012815f2afadb7
ARG EXTENSION_IMAGE=dockersamples/labspace-support-vscode-extension:v0.33.0@sha256:2044d38ff56a23cca6a4890ed0e9ce2f9ec7c1c7f38cbc69fdc5128df1cd52d7
# The workload has no Node, so the overlay carries one. Checked to run on the
# Debian 13 base (glibc is forward compatible).
ARG NODE_IMAGE=node:24-bookworm-slim

FROM ${INTERFACE_IMAGE} AS interface
FROM ${EXTENSION_IMAGE} AS extension
FROM ${NODE_IMAGE} AS node

FROM ${BASE_IMAGE} AS build
USER root

# THE PIN. Supplied by the descriptor's `codeServerVersion` arg; no default on
# purpose, a missing value must fail the build rather than install "latest".
ARG CODE_SERVER_VERSION

RUN <<EOF
set -eux
[ -n "${CODE_SERVER_VERSION}" ] || { echo "CODE_SERVER_VERSION must be set" >&2; exit 1; }
curl -fsSL https://code-server.dev/install.sh | sh -s -- --version "${CODE_SERVER_VERSION}"
reported="$(code-server --version)"
installed="$(printf '%s\n' "$reported" | awk '/^[0-9]/{print $1; exit}')"
[ "$installed" = "${CODE_SERVER_VERSION}" ] || {
  echo "pin mismatch: wanted ${CODE_SERVER_VERSION}, binary reports '$reported'" >&2
  exit 1
}
EOF

# The DHI-based shell kit does not guarantee a writable ~/.local for the agent,
# and code-server needs to create its data directories there.
RUN mkdir -p /home/agent/.local/share/code-server /home/agent/.config \
 && chown 1000:1000 /home/agent/.local/share/code-server /home/agent/.config

# Extensions go into the agent's own extensions directory.
USER agent
RUN code-server --install-extension docker.docker \
 && code-server --install-extension ms-azuretools.vscode-docker
# The extension that powers the interface's Run / Save / open-file buttons.
RUN --mount=from=extension,source=/support-extension.vsix,target=/tmp/support-extension.vsix \
    code-server --install-extension /tmp/support-extension.vsix

USER root

# Interface: the production tree of the published image (node_modules, src,
# public). The image is distroless, so Node comes from its own stage.
COPY --from=interface /usr/local/app /out/opt/labspace/interface
COPY --from=node /usr/local/bin/node /out/opt/labspace/bin/node

# Scripts + VS Code user settings.
COPY files/ /out/

RUN <<'EOF'
set -eux
chmod 0755 /out/opt/labspace/bin/*

# The lab's own icon. The interface's tab icon is /docker.svg; point it at
# /labspace-icon.svg, a link to /labspace/icon.svg, which labspace-stage.sh
# fills at every boot from the lab's labspace/icon.svg (or with docker.svg).
# The link is dangling until then: /labspace only exists in the sandbox.
pub=/out/opt/labspace/interface/public
grep -q 'href="/docker.svg"' "$pub/index.html"
sed -i 's#href="/docker.svg"#href="/labspace-icon.svg"#' "$pub/index.html"
ln -s /labspace/icon.svg "$pub/labspace-icon.svg"

mkdir -p /out/usr/lib /out/usr/bin /out/home/agent/.local/share/code-server /out/etc/labspace-support /out/labspace
cp -a /usr/lib/code-server /out/usr/lib/code-server
cp -a /usr/bin/code-server /out/usr/bin/code-server

# Only the extensions. Not ~/.config/code-server/config.yaml, which holds a
# random generated password and must never be baked into a published layer.
ext=/home/agent/.local/share/code-server/extensions
test -f "$ext/extensions.json"
cp -a "$ext" /out/home/agent/.local/share/code-server/extensions

# /out/home and /out/etc stay as the base has them; only the agent's own
# subtrees are the agent's.
chown -R 1000:1000 /out/home/agent /out/etc/labspace-support /out/labspace
EOF

FROM scratch
COPY --from=build /out /
