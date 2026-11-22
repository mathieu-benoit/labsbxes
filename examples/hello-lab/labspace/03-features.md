# Authoring features

This page shows what a lab author can put in a section's markdown, the same features as the [labspace-starter](https://github.com/dockersamples/labspace-starter) template. Each one works the same inside a Docker Sandbox.

## Code blocks

A code block gets a **Run** button, which types the command into the IDE terminal, and a **Copy** button.

```bash
docker ps
```

Add `no-run-button` to the block's info string to keep only **Copy**, for a command the learner should read or adapt rather than run as is:

```bash no-run-button
docker ps --all --filter status=exited
```

Add `no-copy-button` as well for a block that is only there to be read, such as some output:

```bash no-run-button no-copy-button
CONTAINER ID   IMAGE          COMMAND                  STATUS         PORTS                  NAMES
4f3c2a1b9d8e   nginx:alpine   "/docker-entrypoint.…"   Up 2 minutes   0.0.0.0:3000->80/tcp   web
```

## Save a file

`save-as=<path>` gives the block a **Save** button, which writes the block's content to that path in the project, relative to the project folder:

```plaintext save-as=notes/features.txt
Saved from the "Authoring features" section of the Hello Labspace.
```

Check it from the terminal:

```bash
cat notes/features.txt
```

Or open it in the editor: :fileLink[notes/features.txt]{path="notes/features.txt"}

## Links

A regular markdown link, such as [Docker Hub](https://hub.docker.com), opens in a new browser tab.

A `:tabLink` opens its page in a tab inside this interface, next to the IDE. Start a web server first:

```bash
docker run -d --rm --name web -p 3000:80 nginx:alpine
```

Then open :tabLink[the web app]{href="http://localhost:3000" title="Web app"}.

> [!NOTE]
> Like the previous section, this tab loads `localhost:3000` on your machine, so start the sandbox with `-p 3000:3000`.

Stop the server when you are done:

```bash
docker stop web
```

## Custom variables

A lab can ask the learner for a value once and reuse it everywhere: in the text, in commands the **Run** button sends, and in files the **Save** button writes.

::variableDefinition[username]{prompt="What is your Docker username?"}

The text now shows your answer, **$$username$$**, and so do the commands:

```bash
docker pull -q alpine && docker tag alpine $$username$$/hello-labspace && docker image ls $$username$$/hello-labspace
```

```plaintext save-as=notes/whoami.txt
Docker username: $$username$$
```

```bash
cat notes/whoami.txt
```

Until the variable has a value, it is shown by its name.

In the markdown, the prompt above is a `::variableDefinition` directive: the variable's name goes in the square brackets, and its `prompt` attribute is the question. To use the value, wrap the variable's name in two dollar signs on each side. The substitution applies to the whole page, code blocks included, which is why the syntax is described here rather than shown.
