# Hello Labspace

`ghcr.io/mathieu-benoit/labsbxes/hello-lab`

A minimal lab, packaged as a content kit for the [Labspace kit](../../kit). It shows the two things a Labspace on Docker Sandboxes gives the learner: instructions with **Run** buttons that type into the IDE terminal, and a private Docker engine inside the sandbox, with an nginx container opened in a tab. A third section tours the authoring features a lab can use.

The kit only carries the lab's content (`labspace/` and `project/`), so it always runs together with the Labspace kit.

## Run it

Allow the registry namespace once (by default `sbx` only installs kits from `docker.io/` and `dhi.io/`):

```bash
sbx settings set kit.allowedSources '["docker.io/","dhi.io/","ghcr.io/mathieu-benoit/"]'
```

Start from a dedicated, empty folder, never from your home directory: the folder you start in is mounted into the sandbox.

```bash
mkdir -p ~/sbx-lab && cd ~/sbx-lab
```

```bash
sbx run shell --kit ghcr.io/mathieu-benoit/labsbxes/labspace:0.1.11 --kit ghcr.io/mathieu-benoit/labsbxes/hello-lab:0.1.11 -p 8085:8085 -p 3000:3000 --name hello-lab
```

Then run `sbx port ls hello-lab` and open `http://127.0.0.1:<HOST PORT>/`, with the host port listed for sandbox port 3030. By default that host port is picked by `sbx` and changes at every start. To skip that lookup, add `-p 3030:3030` to the command: the interface is then always at http://localhost:3030 (if that host port is free).

| Pin | Why |
|---|---|
| `-p 8085:8085` | Required: the interface embeds the IDE at `http://localhost:8085` |
| `-p 3000:3000` | For the lab's tab link to `http://localhost:3000` (the nginx container) |
| `-p 3030:3030` | Optional: open the interface at `http://localhost:3030` instead of looking up its host port with `sbx port ls` |

Your edits in the IDE stay in the sandbox and survive `sbx stop` and `sbx run --name hello-lab`, but not `sbx rm hello-lab`.

## What's inside

| Section | |
|---|---|
| Welcome | The instructions and the IDE are two processes in the same microVM |
| Docker inside the sandbox | The sandbox's own engine, bind mounts, and a published port opened in a tab |
| Authoring features | What a lab author can use, as in [labspace-starter](https://github.com/dockersamples/labspace-starter): code blocks with or without **Run** and **Copy**, saving a file, file and tab links, and custom variables |

## Source

This folder is both a content repo and a content kit:

- [labspace/](labspace) and [project/](project): the lab, in the labspace-infra layout
- [hello-lab.yaml](hello-lab.yaml): the descriptor, a mixin that `requires` the Labspace kit, `provides` `labspace-content` and declares port 3000
- [hello-lab.dockerfile](hello-lab.dockerfile): copies the two folders to `/opt/labspace/content`

From a clone of the repository, run it from source with `sbx run shell --kit ./kit --kit ./examples/hello-lab -p 8085:8085 -p 3000:3000 --name hello-lab`. See the [repository README](../../README.md) to package your own lab the same way.
