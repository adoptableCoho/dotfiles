# agent-dotfiles

Version-controlled host config for coding agents, symlinked into place.

| Repo path | Symlinked to |
|---|---|
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `claude/output-styles/` | `~/.claude/output-styles` |

`~/.claude/CLAUDE.md` is the global Claude preferences file. `sbx` shares it
read-only into every sandbox, so the host file is the single source of truth for
host and sandbox alike. The output styles ride along the same way: `sbx` mounts
that directory read-only too, so a style named by the `outputStyle` setting
resolves to a file inside the sandbox as well as on the host.

Both files say how to write. They split on who reads them. `CLAUDE.md` is
loaded for subagents as well as the main conversation, so it carries the short
version of the rule. An output style reaches the main conversation only —
subagents run their own prompt and never see it — so the long version, with the
before and after examples, lives there.

Three rules this layout exists to hold:

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
- **`output-styles` is linked as a whole directory, never file by file.** `sbx`
  bind-mounts that directory into the sandbox, and a bind mount resolves its
  source on the host. Link the directory and the sandbox sees real files. Link
  the files inside a real directory and each one arrives as a symlink to a
  `~/projects/...` path that does not exist in the container, so the style
  silently fails to load. `CLAUDE.md` is immune because `sbx` mounts it as a
  single file. The cost of the directory link is that a machine-local style
  cannot sit beside the tracked ones — add it here instead.

Setup on a new machine:

```sh
git clone <remote> ~/projects/agent-dotfiles
~/projects/agent-dotfiles/install.sh
```

`install.sh` makes both symlinks and sets `"outputStyle": "Plain"` in that
machine's `~/.claude/settings.json`, leaving every other key alone. Nothing else
in `settings.json` is shared — hooks, status line, permissions and plugins are
per-machine. Re-running it is safe: a real file already at a target path is
moved to `<name>.bak-<timestamp>` rather than overwritten.

After a rule changes, `git pull` is enough. The symlinks mean the new text is
live on the next session; `install.sh` only needs re-running if a new file
appeared.
