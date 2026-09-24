#!/usr/bin/env bash
# Set up a new Mac or Ubuntu machine from this repo: tools, languages, the
# config links from install.sh, the ~/projects layout and your repos.
# Run it as your normal user, not root; Homebrew refuses root.
# Safe to re-run: each step skips what is already there.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projects="$HOME/projects"
os="$(uname -s)"

step() { printf '\n==> %s\n' "$*"; }

case "$os" in
  Darwin)
    brew_bin=/opt/homebrew/bin/brew
    step "Xcode command line tools"
    if ! xcode-select -p >/dev/null 2>&1; then
      xcode-select --install
      echo "Finish the installer window, then run this script again."
      exit 1
    fi
    ;;
  Linux)
    brew_bin=/home/linuxbrew/.linuxbrew/bin/brew
    step "apt packages"
    apt_packages=(build-essential procps curl file git zsh)
    sudo apt-get update
    # Ubuntu's mirrors sometimes list a package before they serve it, which
    # fails with a 404. A second try after a fresh update usually gets it.
    if ! sudo apt-get install -y "${apt_packages[@]}"; then
      sleep 10
      sudo apt-get update
      sudo apt-get install -y --fix-missing "${apt_packages[@]}"
    fi
    ;;
  *)
    echo "Unsupported system: $os" >&2
    exit 1
    ;;
esac

step "Homebrew"
if [ ! -x "$brew_bin" ]; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$("$brew_bin" shellenv)"

# Linked before anything is cloned or built, so git already has the gh
# credential helper when the GitHub login and the clones need it.
step "Config links"
"$repo/install.sh"

step "GitHub login"
brew list gh >/dev/null 2>&1 || brew install gh
if ! gh auth status >/dev/null 2>&1; then
  gh auth login --git-protocol https --web
fi

step "oh-my-zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no KEEP_ZSHRC=yes CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
if [ "$os" = Linux ] && [ "$(getent passwd "$(id -un)" | cut -d: -f7)" != "$(command -v zsh)" ]; then
  sudo chsh -s "$(command -v zsh)" "$(id -un)"
fi

# The Brewfile's cargo, uv and npm lines need these three on PATH first.
step "Rust"
if [ ! -x "$HOME/.cargo/bin/rustup" ]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi
export PATH="$HOME/.cargo/bin:$PATH"

step "uv"
if [ ! -x "$HOME/.local/bin/uv" ]; then
  curl -LsSf https://astral.sh/uv/install.sh | env INSTALLER_NO_MODIFY_PATH=1 sh
fi
export PATH="$HOME/.local/bin:$PATH"

step "Node (nvm)"
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | PROFILE=/dev/null bash
fi
# nvm.sh trips set -u.
set +u
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
nvm install --lts
set -u

step "Brewfile"
brew bundle --file="$repo/Brewfile"

# On a Mac these come from the Brewfile as apps.
if [ "$os" = Linux ]; then
  step "Docker and Tailscale"
  if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker "$(id -un)"
  fi
  if ! command -v tailscale >/dev/null 2>&1; then
    curl -fsSL https://tailscale.com/install.sh | sh
  fi
fi

step "Folders and repos"
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
fi

cat <<'EOF'

Left for you to do by hand:
  - Put secrets in ~/.zshrc.local (for example: export GEMINI_API_KEY=...).
  - Copy or create ~/.ssh keys if you use SSH for anything.
  - Sign in to Docker, Tailscale (sudo tailscale up on Linux), fly
    (flyctl auth login) and Claude Code.
Open a new terminal to load the shell config. On Linux, log out and back in
so the new default shell and the docker group take effect.
EOF
