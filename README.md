# dotfiles

Everything needed to set up a new Mac or Ubuntu machine for development, plus
the version-controlled config for coding agents.

## New machine

On Ubuntu, first run `sudo apt-get install -y git`. Then, on either system, as
your normal user rather than root:

```sh
git clone https://github.com/adoptableCoho/dotfiles.git ~/projects/dotfiles
~/projects/dotfiles/bootstrap.sh
```

`bootstrap.sh` first installs what Homebrew needs: the Xcode command line tools
on a Mac, a few apt packages on Ubuntu. Then it installs Homebrew, runs
`install.sh` to link the config files, and asks you to log in to GitHub. After
that it installs oh-my-zsh, Rust, uv, the newest stable Python, Node and
everything in `Brewfile`. On Ubuntu it also installs Docker and Tailscale and
makes zsh your shell. Under WSL it skips Tailscale, which runs on the Windows
side instead. Last, it creates `~/projects/src/{active,archive,external}` and
clones your repos.
Re-running it is safe: each step skips what is already there. It installs what
is missing and upgrades nothing, so it can run on han, whose Homebrew the CI
runners share; upgrading is a separate `brew upgrade`. On a Mac reached only
over SSH, like han, the Brewfile swaps the Tailscale app and Docker Desktop for
colima, since both apps need someone at the screen.

Your own repos are looked up on GitHub at that point, so their names never
appear in this repo. Every live repo in the `coho-dev` organization and in
your personal account goes in `src/active/`. The one exception is
`second-brain`, which goes at the top of `~/projects`. This repo, the
`fixture-*` test repos, archived repos and forks are skipped. `repos.txt` lists only other people's public repos.

Secrets never go in this repo. Put them in `~/.zshrc.local`, which the tracked
`.zshrc` sources and git never sees. SSH keys and app sign-ins are done by hand;
the script prints the list when it finishes.

To keep the setup current: after installing a tool, add a line to `Brewfile`.
`brew bundle cleanup --file=Brewfile` lists anything installed but not in the
file. Don't regenerate it with `brew bundle dump`, because that throws away the
Mac-only block. A new repo of your own needs no change here. After cloning someone else's repo
you want back, add a line to `repos.txt`.

## Config links

| Repo path | Symlinked to |
|---|---|
| `shell/zshrc` | `~/.zshrc` |
| `shell/zprofile` | `~/.zprofile` |
| `shell/zshenv` | `~/.zshenv` |
| `git/gitconfig` | `~/.gitconfig` |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `claude/statusline.sh` | `~/.claude/statusline.sh` |
| `herdr/config.toml` | `~/.config/herdr/config.toml` |
| `ghostty/config` (Mac only) | `~/Library/Application Support/com.mitchellh.ghostty/config` |

herdr's Claude Code and Codex hooks aren't in the table. herdr owns those
scripts and rewrites them on every update, so `bootstrap.sh` runs
`herdr integration install` for each agent instead of linking copies.

`~/.claude/CLAUDE.md` is the global Claude preferences file. `sbx` shares it
read-only into every sandbox, so the host file is the single source of truth for
host and sandbox alike.

`~/.claude/statusline.sh` draws Claude Code's status line. It shows the model
and its reasoning effort, the git branch, whether you are in a worktree, whether
there are uncommitted changes, how much of the context is used, and how far
along the 5-hour and weekly limits are. Labels are gray so the data stands out.
Each percentage is green under 50%, yellow up to 80%, and red above that.
Uncommitted changes show in bold yellow. It needs `jq` and `git`.

Two rules this layout exists to hold:

- **Nothing else from `~/.claude/` is tracked.** It holds OAuth tokens
  (`~/.claude.json`), session history, and caches. The repo root is not `$HOME`,
  so those are unreachable by construction. That is the whole point of the
  symlink over a bare `--work-tree=$HOME` repo.
- **This repo stays outside every sandbox workspace mount.** Today those are
  `~/projects/src` and `~/projects/second-brain`, both mounted read-write. A
  file under one of them would give an agent a writable path to the preferences
  the read-only share exists to protect. Sitting here, next to those folders
  rather than inside them, this repo can't be reached from inside a sandbox.
  So **adding `~/projects` itself as a workspace mount would silently defeat
  this.** Keep the mounts pointed at subfolders.

`install.sh` makes every link in the table above. `bootstrap.sh` runs it for
you; run it on its own when only the links need redoing. `~/.claude/settings.json`
is per-machine, so it isn't linked. `install.sh` changes only its `statusLine`
entry, to point at the script above, and leaves everything else. Re-running it
is safe: a real file already at a target path is moved to
`<name>.bak-<timestamp>` rather than overwritten.

After a change, `git pull` is enough. The links mean the new text is live on
the next session; `install.sh` only needs re-running if a new file appeared.
