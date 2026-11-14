# Labspace on Docker Sandboxes

Run a [Labspace](https://github.com/dockersamples/labspace-infra) (instructions on the left, VS Code on the right, Docker available to the learner) with `sbx run` instead of a seven-container `docker compose up`.

The infrastructure is a single [Sandbox Kit](https://github.com/docker/sandbox-kit-spec) (v3 mixin) that layers onto the built-in `shell` agent.

```bash
sbx run shell --kit ./kit -p 3030:3030 -p 8085:8085 --name my-lab ./examples/hello-lab
```

Then open http://localhost:3030.

- `./examples/hello-lab` is the **content repo**, mounted as the sandbox workspace. It has the same layout as any labspace-infra content repo: `labspace/` (`labspace.yaml` + markdown) and `project/` (what the IDE opens).
- `-p 3030:3030 -p 8085:8085` pins the host ports. The interface embeds the IDE at `http://localhost:8085`, so that one must be pinned. Without `-p`, the kit's `port@1` entries get ephemeral ports (`sbx ports my-lab`) and the IDE panel will not load.
- If those host ports are already taken (for example by a running Compose Labspace), use other ones such as `-p 3031:3030 -p 8086:8085`; the lab opens on the first, but the IDE panel inside it will only load on 8085.
- The command attaches you to a bash session in the sandbox. Add `-d` to start it detached; the kit declares `long-running@1`, so the lab keeps running either way.
- Re-attach with `sbx run --name my-lab`, stop with `sbx stop my-lab`, throw everything away with `sbx rm my-lab`.

## What changed compared to labspace-infra

| labspace-infra (Compose) | This kit | Why |
|---|---|---|
| `socket-proxy` | **Removed** | The sandbox is a microVM with its own Docker engine (`dockerd@1`). The learner's `docker` never reaches the host engine, so there is nothing to filter, label, allowlist or remap. Bind mounts of the project folder just work, since the engine and the files share a filesystem. |
| `workspace-cleaner` | **Removed** | The engine store lives in the sandbox. `sbx rm` deletes every container, volume, network and image the lab created. |
| `host-port-republisher` | **Removed** | Its job was bridging "container publishes a port" to "localhost on the host". Ports are now published by the runtime (`port@1`, `sbx ports`). |
| `configurator` | **Replaced by two small scripts** | `labspace-init.sh` (once: keypair, dirs) and `labspace-stage.sh` (every boot: copy `labspace/` to the instructions dir, write metadata). No git clone, no tarball, no volumes: the content is the workspace. |
| `interface` | **Kept, unchanged** | Reused from the published `dockersamples/labspace-interface` image, copied into the overlay at build time. The built-in `shell` kit (Debian 13) has no Node, so the overlay also carries the `node` binary from `node:24-bookworm-slim`. |
| `workspace` (code-server) | **Kept, built into the overlay** | Same approach as the `code-server` kit in sbx-kits-contrib: pinned install at build time, no download at create. |
| `support-vscode-extension` | **Kept, unchanged** | Reused from `dockersamples/labspace-support-vscode-extension`. The JWT + unix socket between interface and IDE still works, now between two processes in one sandbox. |
| `marlin-mock` | **Removed** | Analytics are off (`analytics_enabled: false`). |
| 4 named volumes, 1 network, 5 `configs` | **None** | |

Net: 7 containers and 5 volumes become 2 processes (`node`, `code-server`) plus the sandbox's own engine.

## Layout

```
kit/
  labspace.yaml          # descriptor: kind mixin, capabilities, lifecycle hooks
  labspace.dockerfile    # builds the overlay (FROM scratch at the end)
  files/
    opt/labspace/bin/    # labspace-init.sh, labspace-stage.sh, labspace-ide.sh, labspace-ui.sh
    home/agent/.local/share/code-server/User/settings.json
examples/hello-lab/      # a tiny content repo to try it with
```

### How a boot goes

1. **Create (once):** `labspace-init.sh` (root) makes `/etc/labspace-support/*` and an ES256 keypair.
2. **Every boot:** the runtime starts the sandbox's Docker engine, then runs the startup hooks in order:
   1. `labspace-stage.sh` stops the boot with a clear error unless `<workspace>/labspace/labspace.yaml` exists; otherwise it stages the instructions and writes the metadata the interface reads.
   2. `labspace-ide.sh` (background) starts code-server on `:8085`, opened on `<workspace>/project`.
   3. `labspace-ui.sh` (background) starts the interface on `:3030`.
3. **Run button:** the browser sends a code block index, the interface reads the command from the markdown on disk, signs a 15 s JWT and POSTs it to the extension's unix socket, and the extension types it in the IDE terminal. Unchanged from labspace-infra.

Logs: `sbx exec my-lab -- cat /tmp/labspace-ui.log /tmp/labspace-ide.log`.

## Options

| Arg | Default | Meaning |
|---|---|---|
| `devMode` | `false` | `--kit-arg devMode=true` reads `<workspace>/labspace` live, so editing a markdown file on the host and reloading the page is enough. |
| `appPort` | `3000` | Extra port published for an app the learner runs. `--kit-arg appPort=8080`. |
| `codeServerVersion` | `4.140.0` | Build-time pin. |

Egress is limited to Docker Hub (for image pulls) and the Open VSX marketplace. A lab that needs more declares it in its own network policy (`sbx policy`), or in a content kit.

## Status

Tested with sbx 0.53 on Windows, using `examples/hello-lab`:

| Checked | Result |
|---|---|
| Build through the kit frontend (descriptor validation included) | Pass |
| `sbx run shell --kit ./kit -d ...` creates the sandbox, install hook and 3 startup hooks run | Pass |
| Interface serves the lab (`/api/labspace` returns the title and sections) | Pass |
| code-server answers and opens `<workspace>/project`; support extension activates and creates its socket | Pass |
| Run button path: `POST .../command` → JWT → unix socket → command typed in the IDE terminal | Pass |
| Private Docker engine inside the sandbox (`docker info`) | Pass |
| `port@1` publishing (`appPort` 3000 → ephemeral host port; 3030/8085 pinned with `-p`) | Pass |
| `docker pull` / `docker run -p 3000:80 nginx:alpine` inside the sandbox, reached from the host through the `appPort` binding | Pass |
| IDE embedded in the interface at `localhost:8085` (split view), with Run, Save and the open-file link clicked in the real UI | Pass |
| `devMode=true`: a markdown edit on the host shows up in the interface without a restart | Pass |
| `sbx stop` then `sbx run --name ... -d`: services come back, hooks re-run cleanly, pulled images are still there | Pass |
| Workspace without `labspace/labspace.yaml`: startup warns with the fix, sandbox still starts | Pass |
| Running the same kit twice on one host, ports pinned to non-default values (3031/8086) | Pass for the interface and IDE; the embedded IDE panel only loads on 8085 |
| macOS / Linux hosts, `--cloud` sandboxes, content bigger than the sample | Not tested |

### Kit network rules and org governance

The kit declares `network-policy@1` (Docker Hub for image pulls, Open VSX for extensions). Under a managed governance policy with default-deny, those rules were **not** applied and `docker pull` failed with `403 Forbidden` from `registry-1.docker.io` (`sbx policy log <name>` shows what was blocked). With governance out of the way, `sbx policy ls` shows them as a `kit`-sourced policy scoped to the sandbox ("managed by a kit; recreated at sandbox create"), and pulls work. If pulls fail on your machine, check `sbx policy log <name>` and `sbx policy ls <name>`.

## Open points

- **One port for everything.** Today the learner must pin `-p 3030:3030 -p 8085:8085` because the interface hard-codes `http://localhost:8085` for the IDE. A gateway (or an `IDE_URL` setting in the interface) serving the IDE under the interface's own port would reduce this to one published port, and could let the kit work with ephemeral ports.
- **Instructions are no longer protected from the learner.** In labspace-infra the interface mounted them read-only. In a sandbox the agent user owns the VM anyway, so this was dropped.
- **Content as a kit.** Today the content is the workspace folder. For distribution, the content repo could be packaged as a second mixin (a `files:` or layer carrying `labspace/` and `project/`) and the two published as a `kind: set`, giving a lab one reference: `sbx run shell --kit docker.io/me/my-lab:1.0.0`.
- **Pin by digest** the `dockersamples/labspace-interface` and `labspace-support-vscode-extension` base images in `labspace.dockerfile`.
- **Init scripts.** labspace-infra ran `/init-scripts/*` in the configurator. The equivalent here would be running an optional `<workspace>/labspace/init.sh` in the install hook.
- The `ttyd` workspace mode in the interface (`WORKSPACE_TYPE=ttyd`) shows the interface already supports a non-VS-Code terminal backend; not used here.
