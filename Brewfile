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
brew "go"
brew "herdr"
brew "golangci-lint"
brew "goreleaser"
brew "jq"
brew "lazygit"
brew "nushell"
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
npm "@fission-ai/openspec"
npm "corepack"

# Mac only. On Ubuntu, bootstrap.sh installs Docker and Tailscale from their
# own install scripts, and the iOS tools have no use.
if OS.mac?
  brew "docker"
  brew "swiftlint"
  brew "xcbeautify"
  cask "docker-desktop"
  cask "font-jetbrains-mono-nerd-font"
  cask "tailscale-app"
end
