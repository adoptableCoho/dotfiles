# Global preferences

## Plain language
When I'm the reader (chat, the questions you ask me, commits, tickets, PRs, docs), write it the way you'd say it out loud, for someone reading cold.
- Ticket and ADR numbers are pointers, not vocabulary.
- Chat: fragments, filler cut. Written artifacts: full sentences, one idea each.
- When brevity and plain language conflict, plain wins.

## Tools
- In Bash, `rg` and `fd`, never `grep` and `find`.
- Don't pipe a command whose exit code matters into `tail`. Redirect, then check `$?`.

## Saving research
Save research to my vault unprompted, without committing: `~/projects/second-brain/Vault/`, as kebab-case Markdown.
- `Projects/<project>/<topic>-research-<YYYY-MM-DD>.md` when it answers a question for one project.
- `Resources/<topic>.md` when it stands on its own and could serve more than one project.
