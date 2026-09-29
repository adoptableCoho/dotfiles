# Tools for every machine. Add a line by hand after installing something new;
# `brew bundle cleanup --file=Brewfile` lists anything installed but missing here.

brew "actionlint"
brew "cmark-gfm"
brew "fd"
brew "ffind"
brew "ffmpeg"
brew "flyctl"
brew "gh"
brew "git"
brew "git-lfs"
brew "glow"
brew "go"
brew "herdr"
brew "golangci-lint"
brew "goreleaser"
brew "jq"
brew "lazygit"
brew "pnpm"
brew "promptfoo"
brew "ripgrep"
brew "shellcheck"
brew "socat"
brew "tmux"
brew "vale"
brew "yq"

# weasyprint and the libraries it draws with.
brew "cairo"
brew "gdk-pixbuf"
brew "libffi"
brew "librsvg"
brew "pango"
brew "weasyprint", link: false

go "golang.org/x/tools/cmd/callgraph"
go "golang.org/x/tools/cmd/goimports"
go "golang.org/x/tools/gopls"
cargo "create-tauri-app"
uv "graphifyy"
# npm packages are in bootstrap.sh: brew bundle runs npm without nvm's Node.

# Mac only. On Ubuntu, bootstrap.sh installs Docker and Tailscale from their
# own install scripts, and the iOS tools have no use.
if OS.mac?
  brew "docker"
  brew "swiftlint"
  brew "xcbeautify"
  cask "font-jetbrains-mono-nerd-font"
  cask "ghostty"
  # A Mac you only reach over SSH, like han, runs Tailscale as a background
  # service so it stays on the tailnet with nobody logged in. The Tailscale app
  # would take it off, and Docker Desktop runs only for whoever is at the
  # screen, so it gets colima: the Docker engine with no app, started over SSH
  # with `colima start`.
  if File.exist?("/Library/LaunchDaemons/com.tailscale.tailscaled.plist")
    brew "colima"
  else
    cask "docker-desktop"
    cask "tailscale-app"
  end
end
