# Option 1: a local folder

The simplest way to run a lab: point `sbx run` at a folder on your machine. That folder becomes the sandbox workspace.

```text
my-lab/
  labspace/
    labspace.yaml
    01-welcome.md
  project/
    README.md
```

Run it from a checkout of the kit, or replace `./kit` with the published reference:

```bash no-run-button
sbx run shell --kit ./kit -p 3030:3030 -p 8085:8085 --name my-lab ./my-lab
```

Then open http://localhost:3030. The interface shows `labspace/`, and the IDE opens `project/`. The two published ports matter: the interface embeds the IDE at `localhost:8085`.

## While you write the lab

Add `--kit-arg devMode=true` and the interface reads `labspace/` live, so saving a Markdown file on your host and reloading the page is enough:

```bash no-run-button
sbx run shell --kit ./kit --kit-arg devMode=true -p 3030:3030 -p 8085:8085 --name my-lab ./my-lab
```

## What to know

- The learner's edits to `project/` are written straight to your folder on the host.
- A folder that already works as a lab under the Docker `labspace-infra` project works here unchanged.
- If your lab links to an app on `localhost` (for example `:tabLink[the app]{href="http://localhost:3000"}`), publish that port on the same host port when you start the sandbox: `-p 3000:3000`.
- To start from a working example, copy [examples/hello-lab](https://github.com/mathieu-benoit/labsbxes/tree/main/examples/hello-lab).
