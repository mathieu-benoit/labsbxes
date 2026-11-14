# Docker inside the sandbox

The `docker` CLI talks to an engine that lives in this sandbox. It is not your host's engine, so there is nothing to clean up afterwards: removing the sandbox removes every image, container and volume created here.

```bash
docker info --format '{{.Name}} / {{.ServerVersion}}'
```

Bind mounts use plain paths, since the project folder is on the same filesystem as the engine:

```bash
docker run --rm -v "$PWD":/work -w /work alpine ls -la
```

Publish a port and open it from your browser:

```bash
docker run -d --rm --name web -p 3000:80 nginx:alpine
```

Then open :tabLink[the app]{href="http://localhost:3000" title="App" id="app"}. It opens as a new tab next to the IDE.

> [!NOTE]
> The tab loads `localhost:3000` on your machine, so the sandbox has to publish its port 3000 on your port 3000: start it with `-p 3000:3000`. Without that flag, the kit still publishes port 3000, but on a random host port, which `sbx ports <sandbox name>` shows.
