#!/usr/bin/env bash
# Claude Code hook → push the agent's state onto its own tmux pane as the
# @claude_blocked and @claude_working options, which wb's status layer and
# the status-left segment read without scanning the screen.
#
# Wired from ~/.claude/settings.json by install.sh:
#   UserPromptSubmit -> claude-notify-hook.sh start        (a turn began)
#   Notification     -> claude-notify-hook.sh needs-input  (agent is asking you)
#   Stop             -> claude-notify-hook.sh done          (turn finished)
#
# Runs inside the agent's TTY, so $TMUX_PANE names the agent's own pane. Every
# call passes it with -t: without -t, tmux acts on the focused pane, so an
# agent finishing while you look elsewhere would mark the wrong pane. No
# $TMUX_PANE (a background session) means nothing is written. Always exits 0
# so a hook can never block or fail Claude.
set -uo pipefail

DONE_MIN_SECS=30   # only flag a finished turn as "done" if it ran at least this long

[ -n "${TMUX_PANE:-}" ] || exit 0
P="$TMUX_PANE"

case "${1:-}" in
  start)        # clear any stale marker, stamp the start time and session id
    tmux set -p -t "$P" @claude_started "$(date +%s)" 2>/dev/null || true
    tmux set -pu -t "$P" @claude_blocked 2>/dev/null || true
    tmux set -p -t "$P" @claude_working 1 2>/dev/null || true
    # Hooks receive JSON on stdin with a session_id. Guarded so a manual,
    # stdin-less invocation can't hang on the read.
    sid=""
    if [ ! -t 0 ]; then
      sid="$(jq -r '.session_id // empty' 2>/dev/null || true)"
      [ -n "$sid" ] && { tmux set -p -t "$P" @claude_session_id "$sid" 2>/dev/null || true; }
    fi
    # A pending /handoff clear is cancelled by any new prompt (KTD3). Only
    # looked up when one exists, so most turns cost a directory listing.
    state="${WB_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/wb}"
    if [ -n "$(ls -A "$state/clear" 2>/dev/null | grep -v '\.claimed$')" ]; then
      "$(dirname "$0")/wb" _clear-cancel ${sid:+--session-id "$sid"} >/dev/null 2>&1 || true
    fi
    ;;
  needs-input)  # blocked on you (permission / question / idle prompt)
    tmux set -p -t "$P" @claude_blocked needs-input 2>/dev/null || true
    ;;
  done)         # always clear working; flag "done" only for long turns
    tmux set -pu -t "$P" @claude_working 2>/dev/null || true
    s="$(tmux show -pv -t "$P" @claude_started 2>/dev/null || true)"
    if [ -n "$s" ] && [ "$(( $(date +%s) - s ))" -ge "$DONE_MIN_SECS" ]; then
      tmux set -p -t "$P" @claude_blocked done 2>/dev/null || true
    fi
    ;;
esac

exit 0
