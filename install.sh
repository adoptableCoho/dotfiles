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

mkdir -p "$dest"
link "$repo/claude/CLAUDE.md" "$dest/CLAUDE.md"

echo "Done. Open a new terminal and restart Claude Code to pick it up."
