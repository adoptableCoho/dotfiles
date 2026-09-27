#!/bin/bash
# Claude Code status line: model and effort, git branch, worktree,
# uncommitted changes (in bold), context used, and the 5-hour and weekly limits.
input=$(cat)

dir=$(jq -r '.workspace.current_dir // .cwd' <<<"$input")
model=$(jq -r '.model.display_name // empty' <<<"$input")
effort=$(jq -r '.effort.level // empty' <<<"$input")
ctx=$(jq -r '
  def k: if . >= 1000000 then "\(. / 100000 | floor / 10)M"
         elif . >= 1000 then "\(. / 1000 | floor)k"
         else tostring end;
  .context_window as $c
  | ($c.current_usage // {}) as $u
  | (($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)) as $used
  | if $c.context_window_size then
      "\($used | k) of \($c.context_window_size | k) (\($c.used_percentage // 0 | floor)%)"
    else "\($c.used_percentage // 0 | floor)%" end' <<<"$input")
five=$(jq -r '.rate_limits.five_hour.used_percentage // empty | floor' <<<"$input")
week=$(jq -r '.rate_limits.seven_day.used_percentage // empty | floor' <<<"$input")

parts=()

if [ -n "$model" ]; then
  [ -n "$effort" ] && model="$model ($effort effort)"
  parts+=("$model")
fi

if branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null); then
  [ -z "$branch" ] && branch="detached at $(git -C "$dir" rev-parse --short HEAD 2>/dev/null)"
  notes=()
  git_dir=$(cd "$dir" && cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
  common=$(cd "$dir" && cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
  [ "$git_dir" != "$common" ] && notes+=("worktree")
  [ -n "$(git -C "$dir" --no-optional-locks status --porcelain 2>/dev/null | head -1)" ] && notes+=($'\e[1muncommitted changes\e[22m')
  if [ ${#notes[@]} -gt 0 ]; then
    branch="$branch ($(IFS='|'; printf '%s' "${notes[*]}" | sed 's/|/, /g'))"
  fi
  parts+=("$branch")
fi

parts+=("context $ctx")
[ -n "$five" ] && parts+=("5-hour limit ${five}%")
[ -n "$week" ] && parts+=("weekly limit ${week}%")

(IFS='|'; printf '%s' "${parts[*]}" | sed 's/|/ · /g')
