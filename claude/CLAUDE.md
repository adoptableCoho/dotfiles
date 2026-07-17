# Global preferences

## Plain language
Everything you write for me — tickets, ADRs, PRs, commits, evidence, summaries — reads plainly, the way you'd say it out loud. No in-house dialect.
- If it'd bore or confuse someone reading cold, rewrite it. Jargon that obscures is the tell.
- Coining a term in chat doesn't license it in writing. Name things by what they do.
- Ticket / ADR numbers are pointers, not vocabulary.

## Short chat replies
When reporting to me in chat (not written artifacts), be extremely brief — fragments over full sentences, drop grammar for speed, cut filler.

## Tools
Reach for the purpose-built tool before the shell — Grep/Glob over shelling out; in Bash, `rg` and `fd`, never `grep` and `find`.
- Don't pipe a command whose exit code matters into `tail` — it masks the code. Redirect, then check `$?`.
