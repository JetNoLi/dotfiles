#!/usr/bin/env bash
# status-left segment (R9): a quiet count of Claude agents that need you,
# from the same status data as the picker. Prints nothing when nothing is
# waiting, so the corner stays empty in the common case.
#
#   ✳N  (magenta) — N agents need you
#   ✔N  (cyan)    — N long-running agents just finished and you haven't looked
#
# Wired in tmux.conf: set -g status-left '#(~/.config/scripts/tmux/claude-status.sh)'
set -uo pipefail

# The status layer needs bash 5; on an older bash, show nothing rather than an error.
[ "${BASH_VERSINFO[0]:-0}" -ge 5 ] || exit 0

lib="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/wb-lib"
source "$lib/compat.sh"
source "$lib/status.sh"

read -r ni dn < <(
  { wb_claude_panes | cut -f3; wb_bg_sessions | awk -F'\t' '$6 == "" { print $5 }'; } \
    | awk '$0 == "needs-input" { n++ } $0 == "done" { d++ } END { print n + 0, d + 0 }'
) || { ni=0; dn=0; }

out=""
[ "${ni:-0}" -gt 0 ] && out="#[fg=magenta,bold]✳${ni}#[default]"
[ "${dn:-0}" -gt 0 ] && out="${out:+$out }#[fg=cyan]✔${dn}#[default]"
[ -n "$out" ] && printf '%s ' "$out"
exit 0
