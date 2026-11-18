#!/usr/bin/env bash
# Assembles the GitHub Pages site: the static files in site/, each kit's
# README.md (listed in site/kits.json) under kits/<id>/, and config.json, which
# names the release the site documents.
#
#   site/build.sh <out dir> [ref] [version]
#
# ref is the git ref the README links point to on GitHub (a tag, or main);
# version is the kit version shown on the page and in the package reference.
set -euo pipefail

out="${1:?usage: site/build.sh <out dir> [ref] [version]}"
ref="${2:-main}"
version="${3:-}"
repo="${GITHUB_REPOSITORY:-mathieu-benoit/labsbxes}"

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"

rm -rf "$out"
mkdir -p "$out"
cp "$here/index.html" "$here/style.css" "$here/app.js" "$here/kits.json" "$out/"
touch "$out/.nojekyll"

# "id" and "dir" pairs, one kit per line, without needing jq.
python3 - "$here/kits.json" <<'PY' | while read -r id dir; do
import json, sys
for k in json.load(open(sys.argv[1], encoding="utf-8")):
    print(k["id"], k["dir"])
PY
  dir="${dir%$'\r'}"
  if [ ! -f "$root/$dir/README.md" ]; then
    echo "::error file=site/kits.json::$dir/README.md not found (kit $id)" >&2
    exit 1
  fi
  mkdir -p "$out/kits/$id"
  cp "$root/$dir/README.md" "$out/kits/$id/README.md"
  echo "kit $id: $dir/README.md"
done

python3 - "$out/config.json" "$repo" "$ref" "$version" <<'PY'
import json, sys
path, repo, ref, version = sys.argv[1:]
json.dump({"repo": repo, "ref": ref, "version": version}, open(path, "w", encoding="utf-8"))
PY

echo "site built in $out (ref $ref${version:+, version $version})"
