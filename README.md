# dotfiles

Version-controlled host config, symlinked into place.

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
- **This repo stays outside `~/projects`.** Those paths are bind-mounted
  read-write into the sandbox. Keeping the real file here means an agent in the
  sandbox has no writable path to it, so the read-only share actually holds.

Setup on a new machine:

```sh
git clone <remote> ~/dotfiles
ln -s ~/dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
```
