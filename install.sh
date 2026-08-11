#!/usr/bin/env bash
# Link this repo's agent config into ~/.claude and set the output style.
# Safe to re-run: an existing symlink is replaced, an existing real file or
# directory is moved aside with a timestamp suffix first.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="$HOME/.claude"
style="Plain"
stamp="$(date +%Y%m%d-%H%M%S)"

link() {
  local from="$1" to="$2"
  if [ -L "$to" ]; then
    rm "$to"
  elif [ -e "$to" ]; then
    mv "$to" "$to.bak-$stamp"
    echo "moved aside: $to -> $to.bak-$stamp"
  fi
  ln -s "$from" "$to"
  echo "linked: $to -> $from"
}

mkdir -p "$dest"
link "$repo/claude/CLAUDE.md" "$dest/CLAUDE.md"
# The whole directory, not the files inside it. sbx bind-mounts this path into
# every sandbox and a bind mount resolves its source on the host, so a linked
# directory arrives as real files. Linked files inside a real directory arrive
# as symlinks to a host path the container does not have, and the style fails
# to load with no error.
link "$repo/claude/output-styles" "$dest/output-styles"

# settings.json is per-machine — hooks, status line, permissions and plugins all
# live there. Only the outputStyle key is shared, so the file is parsed as JSON
# and rewritten rather than edited line by line.
python3 - "$dest/settings.json" "$style" <<'PY'
import json, os, sys
path, style = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path) and os.path.getsize(path):
    with open(path) as f:
        data = json.load(f)
if data.get("outputStyle") == style:
    print("outputStyle already %s" % style)
else:
    data["outputStyle"] = style
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print("set outputStyle = %s in %s" % (style, path))
PY

echo "Done. Restart Claude Code or run /clear to pick it up."
