# Building Container Images: Best Practices

`ghcr.io/mathieu-benoit/labsbxes/building-images-lab` (kit set, ready to run) and `ghcr.io/mathieu-benoit/labsbxes/building-images-lab-mixin` (content kit)

The [labspace-building-images](https://github.com/dockersamples/labspace-building-images) lab from dockersamples, packaged as a content kit for the [Labspace kit](../../kit). The learner takes a small Python web app (the Quote App) and turns a basic Dockerfile into a production-grade image: layer caching, multi-stage builds, non-root users, base images and build secrets, all on the sandbox's own Docker engine.

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
sbx run shell --kit ghcr.io/mathieu-benoit/labsbxes/labspace:0.1.11 --kit ghcr.io/mathieu-benoit/labsbxes/building-images-lab-mixin:0.1.11 -p 8085:8085 -p 5050:5050 --name building-images-lab
```

Or, as a single reference, its kit set (`ghcr.io/mathieu-benoit/labsbxes/building-images-lab`), which merges the `shell` sandbox, the Labspace kit and this kit into one workload:

```bash
sbx run ghcr.io/mathieu-benoit/labsbxes/building-images-lab:0.1.11 -p 8085:8085 -p 5050:5050 --name building-images-lab
```

Then run `sbx port ls building-images-lab` and open `http://127.0.0.1:<HOST PORT>/`, with the host port listed for sandbox port 3030. By default that host port is picked by `sbx` and changes at every start. To skip that lookup, add `-p 3030:3030` to the command: the interface is then always at http://localhost:3030 (if that host port is free).

| Pin | Why |
|---|---|
| `-p 8085:8085` | Required: the interface embeds the IDE at `http://localhost:8085` |
| `-p 5050:5050` | For the lab's Quote App tab at `http://localhost:5050` |
| `-p 3030:3030` | Optional: open the interface at `http://localhost:3030` instead of looking up its host port with `sbx port ls` |

Your edits in the IDE stay in the sandbox and survive `sbx stop` and `sbx run --name building-images-lab`, but not `sbx rm building-images-lab`.

## What's inside

| Section | |
|---|---|
| Welcome & Your First Build | Build and run the Quote App |
| Understanding Image Layers | Read an image's layer history, and why cleaning up in a later layer doesn't shrink it |
| Dockerfile Best Practices | Copy dependencies before source for caching, add a `.dockerignore`, run as a non-root user |
| Multi-Stage Builds | Shrink the image, make tests gate the build, keep dev tools out |
| Choosing a Base Image | Docker Hardened Images, dev vs runtime variants, and tags |
| Build Secrets | Why build arguments leak secrets, and build secrets instead |
| Wrap-up | The final multi-stage Dockerfile and a best-practices checklist |

## Source

- [labspace/](labspace) and [project/](project): copied as they are from [dockersamples/labspace-building-images](https://github.com/dockersamples/labspace-building-images)
- [building-images-lab.yaml](building-images-lab.yaml): the descriptor, a mixin that `requires` the Labspace kit, `provides` `labspace-content` and declares port 5050
- [building-images-lab.dockerfile](building-images-lab.dockerfile): copies the two folders to `/opt/labspace/content`
- [set/building-images-lab-set.yaml](set/building-images-lab-set.yaml): the kit set, `shell` + the Labspace kit + this kit, published as `building-images-lab`

From a clone of the repository, run it from source with `sbx run shell --kit ./kit --kit ./examples/building-images-lab -p 8085:8085 -p 5050:5050 --name building-images-lab`.
