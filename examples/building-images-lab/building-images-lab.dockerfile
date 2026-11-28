# syntax=docker/dockerfile:1.7
#
# Content overlay, fetched from the lab's own repository instead of copied
# from this folder: BuildKit checks out CONTENT_REPO at CONTENT_REF (both from
# the descriptor's args) and only its labspace/ and project/ folders land where
# the Labspace kit looks for them. The rest of that repository (its Compose
# files, CI, docs) is left out. No scripts, no tools, no base: `FROM scratch`,
# so it composes onto whatever the workload is.
#
# The fetch happens at build time only: the published kit carries the files,
# so the sandbox needs no access to GitHub, and a published version never
# changes when the repository does.
FROM scratch AS content
ARG CONTENT_REPO
ARG CONTENT_REF
ADD --keep-git-dir=false ${CONTENT_REPO}#${CONTENT_REF} /

FROM scratch
COPY --from=content /labspace /opt/labspace/content/labspace
COPY --from=content /project /opt/labspace/content/project
