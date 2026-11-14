# Docker inside the sandbox

The `docker` CLI talks to an engine that lives in this sandbox. It is not your host's engine, so there is nothing to clean up afterwards: removing the sandbox removes every image, container and volume created here.

```bash
docker info --format '{{.Name}} / {{.ServerVersion}}'
```

Bind mounts use plain paths, since the project folder is on the same filesystem as the engine:

```bash
docker run --rm -v "$PWD":/work -w /work alpine ls -la
```

Publish a port and open it from your browser (the kit publishes port 3000 by default):

```bash
docker run -d --rm --name web -p 3000:80 nginx:alpine
```

Then open ::tabLink[the app]{href="http://localhost:3000" title="App" id="app"}.
