#!/usr/bin/env bash
# Link this repo's shell, git and agent config into $HOME.
# Safe to re-run: an existing symlink is replaced, an existing real file or
# directory is moved aside with a timestamp suffix first.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="$HOME/.claude"
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

link "$repo/shell/zshrc" "$HOME/.zshrc"
link "$repo/shell/zprofile" "$HOME/.zprofile"
link "$repo/shell/zshenv" "$HOME/.zshenv"
link "$repo/git/gitconfig" "$HOME/.gitconfig"

mkdir -p "$HOME/.config/herdr"
link "$repo/herdr/config.toml" "$HOME/.config/herdr/config.toml"

# The Ghostty config binds Cmd keys, so it's Mac only.
if [ "$(uname -s)" = Darwin ]; then
  ghostty_dir="$HOME/Library/Application Support/com.mitchellh.ghostty"
  mkdir -p "$ghostty_dir"
  link "$repo/ghostty/config" "$ghostty_dir/config"
fi

mkdir -p "$dest"
link "$repo/claude/CLAUDE.md" "$dest/CLAUDE.md"
link "$repo/claude/statusline.sh" "$dest/statusline.sh"

# settings.json is per-machine, so set only the status line entry and keep the
# rest of the file as it is.
python3 - "$dest/settings.json" <<'EOF'
import json, os, sys
path = sys.argv[1]
settings = json.load(open(path)) if os.path.exists(path) else {}
want = {"type": "command", "command": "~/.claude/statusline.sh"}
if settings.get("statusLine") != want:
    settings["statusLine"] = want
    with open(path, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
    print(f"set: status line in {path}")
EOF

echo "Done. Open a new terminal and restart Claude Code to pick it up."
