#!/bin/bash
# Claude Code status line: model and effort, git branch, worktree,
# uncommitted changes, context used, and the 5-hour and weekly limits.
# Labels are gray and data is bright; percentages go green, yellow, then red.
input=$(cat)

gray=$'\e[90m' cyan=$'\e[36m' yellow=$'\e[33m' bold=$'\e[1m' reset=$'\e[0m'

# The percentage, colored by how close it is to full.
pct() {
  local color=$'\e[32m'
  if [ "$1" -gt 80 ]; then color=$'\e[31m'
  elif [ "$1" -ge 50 ]; then color=$'\e[33m'; fi
  printf '%s%s%%%s' "$color" "$1" "$reset"
}
label() { printf '%s%s%s' "$gray" "$1" "$reset"; }

dir=$(jq -r '.workspace.current_dir // .cwd' <<<"$input")
model=$(jq -r '.model.display_name // empty' <<<"$input")
effort=$(jq -r '.effort.level // empty' <<<"$input")
used=$(jq -r '
  def k: if . >= 1000000 then "\(. / 100000 | floor / 10)M"
         elif . >= 1000 then "\(. / 1000 | floor)k"
         else tostring end;
  .context_window as $c
  | ($c.current_usage // {}) as $u
  | (($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)) as $used
  | if $c.context_window_size then "\($used | k) of \($c.context_window_size | k)" else empty end' <<<"$input")
ctx_pct=$(jq -r '.context_window.used_percentage // 0 | floor' <<<"$input")
five=$(jq -r '.rate_limits.five_hour.used_percentage // empty | floor' <<<"$input")
week=$(jq -r '.rate_limits.seven_day.used_percentage // empty | floor' <<<"$input")

parts=()

if [ -n "$model" ]; then
  [ -n "$effort" ] && model="$model $effort $(label effort)"
  parts+=("$model")
fi

if branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null); then
  [ -z "$branch" ] && branch="detached at $(git -C "$dir" rev-parse --short HEAD 2>/dev/null)"
  branch="$cyan$branch$reset"
  notes=()
  git_dir=$(cd "$dir" && cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
  common=$(cd "$dir" && cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
  [ "$git_dir" != "$common" ] && notes+=("${yellow}worktree$reset")
  [ -n "$(git -C "$dir" --no-optional-locks status --porcelain 2>/dev/null | head -1)" ] && notes+=("$bold${yellow}uncommitted changes$reset")
  if [ ${#notes[@]} -gt 0 ]; then
    branch="$branch ($(IFS='|'; printf '%s' "${notes[*]}" | sed 's/|/, /g'))"
  fi
  parts+=("$branch")
fi

parts+=("$(label context) ${used:+$used }$(pct "$ctx_pct")")
[ -n "$five" ] && parts+=("$(label '5-hour limit') $(pct "$five")")
[ -n "$week" ] && parts+=("$(label 'weekly limit') $(pct "$week")")

line=${parts[0]}
for part in "${parts[@]:1}"; do line+=" ${gray}·${reset} $part"; done
printf '%s' "$line"
