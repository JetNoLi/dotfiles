#!/usr/bin/env bash
# claude-statusline.sh — Claude Code's statusLine: context %, the wb task,
# the worktree, model and effort, then plan usage, right-aligned. Ported
# from the work machine's statusline.sh, which shows the session name where
# this shows the task and worktree. Reads Claude Code's JSON on stdin; the
# fields are documented at code.claude.com/docs/en/statusline.
#
# - Task: the tmux session's @task (set by wb), else its @wb_repo--@wb_slug.
#   A background session has no pane, so its session_name stands in; wb new
#   --bg names it for the task stem.
# - Worktree: workspace.git_worktree in a linked worktree, else the repo's
#   folder name (one git call), else nothing outside git.
# - Plan usage (`5h 42% ↻1h20m · wk 18% ↻3d4h`): rate_limits is sent only to
#   Pro/Max subscribers after the first API response, and each window can be
#   absent on its own.
#
# It runs under the Mac's /bin/bash 3.2 too, and must always print a line.
set -uo pipefail

payload="$(cat)"
field() { jq -r "$1 // empty" <<<"$payload" 2>/dev/null; }

pct="$(field '.context_window.used_percentage | floor')"; pct="${pct:-0}"
model="$(field '.model.display_name // .model.id')"; model="${model:-?}"
effort="$(field '.effort.level')"
session_name="$(field '.session_name')"
cwd="$(field '.workspace.current_dir // .cwd')"
worktree="$(field '.workspace.git_worktree')"
read -r h5_pct h5_reset < <(jq -r '.rate_limits.five_hour // empty
  | "\((.used_percentage // empty) + 0.5 | floor) \(.resets_at // "")"' <<<"$payload" 2>/dev/null) || true
read -r wk_pct wk_reset < <(jq -r '.rate_limits.seven_day // empty
  | "\((.used_percentage // empty) + 0.5 | floor) \(.resets_at // "")"' <<<"$payload" 2>/dev/null) || true

task=""
if [ -n "${TMUX_PANE:-}" ]; then
  IFS='|' read -r t_file t_repo t_slug < <(tmux display -p -t "$TMUX_PANE" '#{@task}|#{@wb_repo}|#{@wb_slug}' 2>/dev/null) || true
  if [ -n "${t_file:-}" ]; then
    task="${t_file##*/}"; task="${task%.md}"
  elif [ -n "${t_repo:-}" ] && [ -n "${t_slug:-}" ]; then
    task="$t_repo--$t_slug"
  fi
fi
[ -n "$task" ] || task="$session_name"

if [ -z "$worktree" ] && [ -n "$cwd" ]; then
  top="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" && worktree="${top##*/}"
fi

# traffic-light thresholds — context, and the plan-usage windows the same way
traffic() { # <pct 0-100>
  if   [ "$1" -ge 85 ]; then printf '\033[38;2;210;15;57m'   # crit (Catppuccin red)
  elif [ "$1" -ge 60 ]; then printf '\033[38;2;223;142;29m'  # warn (Catppuccin yellow)
  else                       printf '\033[38;2;64;160;43m'   # ok   (Catppuccin green)
  fi
}
reset=$'\033[0m'
dim=$'\033[2m'
accent=$'\033[38;2;136;57;239m'  # Catppuccin mauve
sep="${dim} · ${reset}"
plain_sep=" · "

line="$(traffic "$pct")${pct}%${reset} ctx"
plain="${pct}% ctx"
part() { # <colored> <plain> — append one segment
  line="${line}${sep}$1"
  plain="${plain}${plain_sep}$2"
}
[ -z "$task" ] || part "${accent}${task}${reset}" "$task"
[ -z "$worktree" ] || part "${dim}⎇${reset} ${worktree}" "⎇ ${worktree}"
part "$model" "$model"
[ -z "$effort" ] || part "${dim}${effort}${reset}" "$effort"

# compact countdown to an epoch-seconds reset: 3d4h / 1h20m / 20m; blank if past
until_reset() { # <epoch>
  local left=$(( $1 - $(date +%s) ))
  [ "$left" -gt 0 ] || return 0
  if   [ "$left" -ge 86400 ]; then printf '%dd%dh' $(( left / 86400 )) $(( left % 86400 / 3600 ))
  elif [ "$left" -ge 3600 ];  then printf '%dh%02dm' $(( left / 3600 )) $(( left % 3600 / 60 ))
  else                             printf '%dm' $(( left / 60 ))
  fi
}
usage_part() { # <label> <pct> <resets_at>
  [[ "$2" =~ ^[0-9]+$ ]] || return 0
  local p="$1 $2%" c when=""
  c="${dim}$1${reset} $(traffic "$2")$2%${reset}"
  [[ "$3" =~ ^[0-9]+$ ]] && when="$(until_reset "$3")"
  if [ -n "$when" ]; then
    p="$p ↻$when"
    c="$c ${dim}↻$when${reset}"
  fi
  part "$c" "$p"
}
usage_part 5h "${h5_pct:-}" "${h5_reset:-}"
usage_part wk "${wk_pct:-}" "${wk_reset:-}"

cols="${COLUMNS:-80}"
pad=$(( cols - ${#plain} ))
[ "$pad" -lt 0 ] && pad=0
printf '%*s%s' "$pad" "" "$line"
