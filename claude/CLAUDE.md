# Global preferences

## Plain language
When I'm the reader (tickets, ADRs, PRs, commits, evidence, summaries, chat, and the questions you ask me), write it the way you'd say it out loud, for someone reading cold.
- Ticket / ADR numbers are pointers, not vocabulary.
- Chat: fragments, filler cut. Written artifacts: full sentences, one idea each.
- When brevity and plain language conflict, plain wins and you spend the extra sentence.

## Tools
In Bash, `rg` and `fd`, never `grep` and `find`.
- Don't pipe a command whose exit code matters into `tail` — it masks the code. Redirect, then check `$?`.
