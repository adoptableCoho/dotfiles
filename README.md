# agent-dotfiles

Version-controlled host config for coding agents, symlinked into place.

| Repo path | Symlinked to |
|---|---|
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |

`~/.claude/CLAUDE.md` is the global Claude preferences file. `sbx` shares it
read-only into every sandbox, so the host file is the single source of truth for
host and sandbox alike.

Two rules this layout exists to hold:

- **Nothing else from `~/.claude/` is tracked.** It holds OAuth tokens
  (`~/.claude.json`), session history, and caches. The repo root is not `$HOME`,
  so those are unreachable by construction — that is the whole point of the
  symlink over a bare `--work-tree=$HOME` repo.
- **This repo stays outside every sandbox workspace mount.** Today those are
  `~/projects/src` and `~/projects/second-brain`, both bind-mounted *read-write*.
  A real file under one of them would hand an agent a writable path to the very
  preferences the read-only share exists to protect — the read-only mount refuses
  the write, but the workspace path happily takes it. Sitting here, a sibling of
  those directories, there is no path to this repo from inside a sandbox at all.

  So the tripwire: **adding `~/projects` itself as a workspace mount would
  silently defeat this.** Keep the mounts pointed at subdirectories.

Setup on a new machine:

```sh
git clone <remote> ~/projects/agent-dotfiles
ln -s ~/projects/agent-dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
```
