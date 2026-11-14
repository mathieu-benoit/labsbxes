# No lab loaded

The Labspace kit is running, but it found **no lab content**, so you are looking at its built-in getting-started lab.

It looked in the workspace folder, `@@WORKSPACE@@`, for a `labspace/labspace.yaml`, and no content kit was composed in. Nothing is wrong with the sandbox: the interface on the left and the IDE on the right are working, and there is a private Docker engine behind them.

A lab is two folders:

| Folder | What it is |
|---|---|
| `labspace/` | `labspace.yaml` and the Markdown sections you are reading now |
| `project/` | The starter files the learner works on, opened in the IDE |

There are three ways to give the sandbox a lab. Pick the one that matches what you are doing:

| You want to... | Use | Where the learner's files live |
|---|---|---|
| Write or try a lab, or run a demo | **Option 1**: a local folder | On your host, in the folder |
| Hand a lab to someone | **Option 2**: a content kit | In the sandbox |
| Hand a lab over with a single reference | **Option 3**: a set | In the sandbox |

Use the menu at the bottom to read them in order, or jump to the one you need.

> [!NOTE]
> This sandbox was created without a lab. Remove it with `sbx rm @@SANDBOX@@` and start again with one of the options, or keep it and use it to scaffold a lab (Option 2).
