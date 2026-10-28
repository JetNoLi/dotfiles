#!/usr/bin/env bash
# claude-notify-hook.sh pane markers, and the settings merge that wires it.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
set +e

HOOK="$(dirname "$WB")/claude-notify-hook.sh"
MERGE="$(dirname "$WB")/claude-hooks-merge.sh"
tmux new-session -d -s h "sleep 300"
P="$(tmux list-panes -t "=h:" -F '#{pane_id}')"
opt() { tmux show -pv -t "$P" "$1" 2>/dev/null; }

echo '{"session_id":"abc-123"}' | TMUX_PANE="$P" "$HOOK" start
assert_eq "start sets @claude_working" 1 "$(opt @claude_working)"
assert_eq "start records the session id" abc-123 "$(opt @claude_session_id)"

TMUX_PANE="$P" "$HOOK" needs-input < /dev/null
assert_eq "needs-input sets @claude_blocked" needs-input "$(opt @claude_blocked)"

TMUX_PANE="$P" "$HOOK" start < /dev/null
assert_eq "start clears a stale block" "" "$(opt @claude_blocked)"
TMUX_PANE="$P" "$HOOK" done
assert_eq "a short turn's done leaves no marker" "" "$(opt @claude_blocked)"
assert_eq "done clears @claude_working" "" "$(opt @claude_working)"

tmux set -p -t "$P" @claude_started "$(( $(date +%s) - 31 ))"
TMUX_PANE="$P" "$HOOK" done
assert_eq "done after 30 seconds sets done" done "$(opt @claude_blocked)"

out="$(TMUX_PANE= "$HOOK" needs-input; echo "exit=$?")"
assert_eq "with no pane (a background session) the hook does nothing and exits 0" exit=0 "$out"

# --- settings merge ---------------------------------------------------------------
s="$T/settings.json"
echo '{"theme":"dark","hooks":{"Stop":[{"hooks":[{"type":"command","command":"other"}]}]}}' > "$s"
"$MERGE" "$s"; "$MERGE" "$s"
assert_eq "other keys are kept" dark "$(jq -r .theme "$s")"
assert_eq "an existing hook on the same event is kept" other "$(jq -r '.hooks.Stop[0].hooks[0].command' "$s")"
for ev in UserPromptSubmit Notification Stop; do
  assert_eq "$ev gets the notify hook once after two merges" 1 \
    "$(jq --arg ev "$ev" '[.hooks[$ev][].hooks[].command | select(test("claude-notify-hook"))] | length' "$s")"
done
assert_eq "Stop runs the hook with done" "~/.config/scripts/tmux/claude-notify-hook.sh done" \
  "$(jq -r '.hooks.Stop[1].hooks[0].command' "$s")"

finish
