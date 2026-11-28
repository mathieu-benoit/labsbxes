# Option 2: a content kit

To hand a lab to someone, package its two folders as a **content kit**: a small mixin that carries the lab and composes with the Labspace kit. The lab no longer depends on a folder on the learner's machine.

## Scaffold a starter lab

Each **Save** button below writes one file into the IDE project, under `my-lab/`. Click them in order.

The lab definition:

```yaml save-as=my-lab/labspace/labspace.yaml
metadata:
  id: me/my-lab

title: My lab
description: What this lab teaches.

sections:
  - title: Welcome
    contentPath: 01-welcome.md
```

The first section. Write plain Markdown; any `bash` code block you add gets a Run button that types the command into the IDE terminal.

```markdown save-as=my-lab/labspace/01-welcome.md
# Welcome

Replace this with your first instructions.
```

The starter project the learner works on:

```markdown save-as=my-lab/project/README.md
# Project

The learner works in this folder.
```

The two files that turn the folder into a kit:

```yaml save-as=my-lab/my-lab.yaml
# syntax=docker/sandbox-kit:3
schemaVersion: "3"
kind: mixin

displayName: My lab (content)
description: The content of my lab, to be run by the Labspace kit.
version: "1.0.0"

# Refused at resolution if the Labspace kit is not part of the composition.
requires: ["labspace >= 0.1.0"]

# One lab per sandbox: a second content kit would provide the same name.
provides: ["labspace-content@1.0.0"]

# If the lab runs an app the learner opens in a browser, declare its port:
# it is published as soon as the sandbox is created, on a host port that sbx
# picks (sbx port ls <name>).
# capabilities:
#   - type: com.docker.sandbox/port@1
#     config:
#       container: 3000
```

```dockerfile save-as=my-lab/my-lab.dockerfile
# syntax=docker/dockerfile:1.7
FROM scratch
COPY labspace /opt/labspace/content/labspace
COPY project /opt/labspace/content/project
```

## Copy it out and run it

From a terminal on your machine (these run on your host, not in the sandbox):

```bash no-run-button
sbx cp @@SANDBOX@@:/home/agent/project/my-lab ./my-lab
```

Edit it, then start a new sandbox from a dedicated, empty folder, composing the Labspace kit with your content kit. The folder you start from is mounted into the sandbox, so never start from your home directory, which would expose your keys and credentials to it:

```bash no-run-button
sbx run shell --kit ./kit --kit ./my-lab -p 8085:8085 --name my-lab
sbx port ls my-lab
```

Open the host port listed for sandbox port 3030.

## What to know

- With a content kit, `project/` is copied once into the sandbox. The learner's edits stay in the sandbox and survive `sbx stop` and `sbx run`, but not `sbx rm`.
- A kit that is not composed with the Labspace kit fails with `requires "labspace >= 0.1.0"`, and two content kits conflict.
- If the lab already lives in its own Git repository, the content kit can fetch its `labspace/` and `project/` at build time instead of keeping a copy, pinned to a commit. See how `examples/building-images-lab` does it in [mathieu-benoit/labsbxes](https://github.com/mathieu-benoit/labsbxes#content-from-another-repository).
- To give the lab its own browser tab icon, add an SVG as `my-lab/labspace/icon.svg`, next to `labspace.yaml`. Without one, the tab shows the Docker logo.
- If the workspace folder itself contains a `labspace/labspace.yaml`, it takes priority over the content kit.
- A port declared with `port@1` gets a host port that `sbx` picks, and picks again at every start: a kit can't choose it. If the lab links to the app on a fixed `localhost` port, the learner still pins it with `-p`, for example `-p 3000:3000`.
