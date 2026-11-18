# syntax=docker/dockerfile:1.7
#
# Content overlay: the lab's two folders, landing where the Labspace kit looks
# for them. No scripts, no tools, no base: `FROM scratch`, so it composes onto
# whatever the workload is.
FROM scratch
COPY labspace /opt/labspace/content/labspace
COPY project /opt/labspace/content/project
