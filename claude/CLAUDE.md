# Global preferences

## Plain language
Everything you write for me — tickets, ADRs, PRs, commits, evidence, summaries, and chat, including the questions you ask me — reads plainly, the way you'd say it out loud. No in-house dialect.
- If it'd bore or confuse someone reading cold, rewrite it.
- Ticket / ADR numbers are pointers, not vocabulary.
- Chat replies are extremely brief — fragments over full sentences, filler cut. Written artifacts go the other way: full sentences, one idea each.
- When brevity and plain language conflict, plain wins and you spend the extra sentence.

## Tools
In Bash, `rg` and `fd`, never `grep` and `find`.
- Don't pipe a command whose exit code matters into `tail` — it masks the code. Redirect, then check `$?`.
