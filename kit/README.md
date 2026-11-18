# Labspace kit

`ghcr.io/mathieu-benoit/labsbxes/labspace`

A [Sandbox Kit](https://github.com/docker/sandbox-kit-spec) (v3 mixin) that runs a [Labspace](https://github.com/dockersamples/labspace-infra) inside a Docker Sandbox: the instructions on the left, VS Code (code-server) on the right, and a private Docker engine for the learner. It layers onto the built-in `shell` agent and replaces the labspace-infra Compose stack.

The kit carries the runtime, not a lab. The lab comes from one of these, first match wins:

1. a folder mounted as the workspace that has `labspace/labspace.yaml` (authoring, demos)
2. a content kit composed with it, such as [hello-lab](../examples/hello-lab) or [building-images-lab](../examples/building-images-lab)
3. neither: a built-in getting-started lab that explains how to add one

## Run it

Allow the registry namespace once (by default `sbx` only installs kits from `docker.io/` and `dhi.io/`):

```bash
sbx settings set kit.allowedSources '["docker.io/","dhi.io/","ghcr.io/mathieu-benoit/"]'
```

Start from a dedicated, empty folder, never from your home directory: the folder you start in is mounted into the sandbox.

```bash
mkdir -p ~/sbx-lab && cd ~/sbx-lab
```

The built-in getting-started lab:

```bash
sbx run shell --kit ghcr.io/mathieu-benoit/labsbxes/labspace:0.1.6 -p 8085:8085 --name labspace
```

With a lab packaged as a content kit:

```bash
sbx run shell --kit ghcr.io/mathieu-benoit/labsbxes/labspace:0.1.6 --kit ghcr.io/mathieu-benoit/labsbxes/hello-lab:0.1.6 -p 8085:8085 -p 3000:3000 --name hello-lab
```

Then run `sbx ports <name>` and open `http://127.0.0.1:<HOST PORT>/`, with the host port listed for sandbox port 3030. By default that host port is picked by `sbx` and changes at every start. To skip that lookup, add `-p 3030:3030` to the command: the interface is then always at http://localhost:3030 (if that host port is free).

- Re-attach with `sbx run --name <name>`, stop with `sbx stop <name>`, remove everything with `sbx rm <name>`.
- Add `-d` to start detached. The kit declares `long-running@1`, so the lab keeps running either way.

## Ports

The kit publishes these sandbox ports at create, each on a host port `sbx` picks. Pin a host port with `-p` only where something expects a fixed `localhost` address.

| Sandbox port | What | Pin it? |
|---|---|---|
| 3030 | Labspace interface | Optional: `-p 3030:3030` to always open `http://localhost:3030` |
| 8085 | code-server (VS Code) | **Required**: `-p 8085:8085`, the interface embeds the IDE at `http://localhost:8085` |
| `appPort` (3000) | An app the learner runs | Only if the lab links to it at a fixed `localhost` port |

## Options

| Kit arg | Default | What it does |
|---|---|---|
| `appPort` | `3000` | Extra port to publish for the learner's app: `--kit-arg appPort=8080` |
| `devMode` | `false` | Content authoring: `true` reads `<workspace>/labspace` live, so editing a markdown file on the host and reloading the page shows the change |
| `codeServerVersion` | `4.140.0` | code-server release built into the kit (build time) |

## Source

- [labspace.yaml](labspace.yaml): the descriptor (capabilities, ports, network policy, lifecycle hooks)
- [labspace.dockerfile](labspace.dockerfile): builds the overlay
- [files/](files): the startup scripts and the built-in lab

See the [repository README](../README.md) for how a boot goes, how to package a lab as a kit, and how the kits are published.
