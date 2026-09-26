#!/usr/bin/env bash
# Set up a new Mac or Ubuntu machine from this repo: tools, languages, the
# config links from install.sh, and your repos via clone-repos.sh.
# Run it as your normal user, not root; Homebrew refuses root.
# Safe to re-run: each step skips what is already there.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
# Homebrew belongs to the account that installed it. On a shared machine, such
# as a CI box with a non-admin build account, every install from another account
# fails. So stop here, before anything in this account's home is changed.
brew_prefix="$(dirname "$(dirname "$brew_bin")")"
if [ -x "$brew_bin" ] && [ ! -w "$brew_prefix/Cellar" ]; then
  echo "Homebrew at $brew_prefix belongs to $(stat -f %Su "$brew_prefix" 2>/dev/null || stat -c %U "$brew_prefix") and $(id -un) can't write to it." >&2
  echo "Run this from that account, or not on this machine. Nothing has been changed." >&2
  exit 1
fi
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
  # Under WSL, Tailscale runs on Windows and WSL shares its network, so a copy
  # in here would only fight it over routes and DNS.
  if grep -qi microsoft /proc/version; then
    echo "WSL: skipping Tailscale, which belongs on the Windows side"
  elif ! command -v tailscale >/dev/null 2>&1; then
    curl -fsSL https://tailscale.com/install.sh | sh
  fi
fi

step "Repos"
# A failed clone is listed and doesn't stop the rest of the setup.
"$repo/clone-repos.sh" || true

cat <<'EOF'

Left for you to do by hand:
  - Put secrets in ~/.zshrc.local (for example: export GEMINI_API_KEY=...).
  - Copy or create ~/.ssh keys if you use SSH for anything.
  - Sign in to Docker, Tailscale (sudo tailscale up on Linux), fly
    (flyctl auth login) and Claude Code.
Open a new terminal to load the shell config. On Linux, log out and back in
so the new default shell and the docker group take effect.
EOF
