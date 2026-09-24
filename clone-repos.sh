#!/usr/bin/env bash
# Clone your repos into ~/projects, and the public ones in repos.txt.
# Needs `gh` logged in. A folder that already exists is left alone, so this is
# safe to re-run. Exits 1 if any repo failed to clone, after trying them all.
#
# bootstrap.sh runs this. Run it on its own on a machine whose tools are set up
# some other way, such as a homelab host.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projects="$HOME/projects"

mkdir -p "$projects/src/active" "$projects/src/archive" "$projects/src/external"

# Your own repos are looked up on GitHub rather than listed in this repo, so
# their names stay private. Archived repos and forks are left out.
# Live repos from both accounts go in src/active, except second-brain, which
# goes at the top of ~/projects. This repo and the throwaway test fixtures
# are skipped.
own_repos() {
  gh repo list coho-dev --limit 500 --no-archived --source --json name,url \
    --jq '.[] | "src/active/\(.name) \(.url).git"'
  gh repo list adoptableCoho --limit 500 --no-archived --source --json name,url \
    --jq '.[] | select(.name != "dotfiles" and (.name | startswith("fixture-") | not))
                | "\(if .name == "second-brain" then "" else "src/active/" end)\(.name) \(.url).git"'
}

failed=()
while read -r dir url; do
  case "$dir" in ''|'#'*) continue ;; esac
  if [ -e "$projects/$dir" ]; then
    echo "exists: $dir"
  elif git clone "$url" "$projects/$dir"; then
    echo "cloned: $dir"
  else
    failed+=("$dir")
  fi
done < <(own_repos; cat "$repo/repos.txt")

if [ ${#failed[@]} -gt 0 ]; then
  printf '\nThese repos did not clone:\n'
  printf '  %s\n' "${failed[@]}"
  exit 1
fi
