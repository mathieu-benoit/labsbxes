# Option 3: one reference

Learners should not have to compose two kits. A **set** merges the Labspace kit and your content kit into one published kit, so a lab is a single reference.

Both kits go to a registry first, then the set that lists them (a set can only list registry references, not local folders):

```yaml
# my-lab-set.yaml
# syntax=docker/sandbox-kit:3
schemaVersion: "3"
kind: set
displayName: My lab (ready to run)
version: "1.0.0"

kits:
  - ref: docker.io/YOU/labspace:0.1.0
  - ref: docker.io/YOU/my-lab:1.0.0
```

Build and push with a `docker-container` builder (`docker buildx create --name kit-builder --driver docker-container --bootstrap`):

```bash no-run-button
docker buildx build --builder kit-builder ./kit -f ./kit/labspace.yaml -t docker.io/YOU/labspace:0.1.0 --push
docker buildx build --builder kit-builder ./my-lab -f ./my-lab/my-lab.yaml -t docker.io/YOU/my-lab:1.0.0 --push
docker buildx build --builder kit-builder . -f my-lab-set.yaml -t docker.io/YOU/my-lab-set:1.0.0 --push
```

Learners then run:

```bash no-run-button
sbx run shell --kit docker.io/YOU/my-lab-set:1.0.0 -p 3030:3030 -p 8085:8085
```

## What to know

- The published set is one ordinary kit. It pins both members by digest and carries their combined settings.
- `sbx` only installs kits from registries allowed by its `kit.allowedSources` setting, which defaults to `docker.io/` and `dhi.io/`.
- Bumping the Labspace kit means republishing every set that includes it. Keeping the content kit separate (Option 2) avoids that, at the cost of two references.
