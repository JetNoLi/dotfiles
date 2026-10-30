#!/usr/bin/env bash
# claude-pickup-hook.sh: what a clean start of a task's session is given.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e

HOOK="$(dirname "$WB")/claude-pickup-hook.sh"
ctx() { jq -r '.hookSpecificOutput.additionalContext // empty'; }
# start <source> [session_id] — run the hook for the pane in $P.
start() { printf '{"source":"%s","session_id":"%s"}' "$1" "${2:-}" | TMUX_PANE="${P:-}" "$HOOK"; }

f="$TASKS_DIR/proj--pick.md"
printf -- '---\nstatus: doing\n---\n# Pick\n\n## Handoffs\n\n### 2026-10-02 14:02 — checkpoint\n\nDone: a\nNext: run the migration\n\n### 2026-10-02 15:10 — wb down (auto)\n\nParked.\n\n## Decisions\n' > "$f"
tmux new-session -d -s proj--pick "sleep 300"
tmux set-option -t "=proj--pick:" @task "$f" >/dev/null
P="$(tmux list-panes -t "=proj--pick:" -F '#{pane_id}')"

out="$(start clear | ctx)"
assert "AE1: a clear start gets the checkpoint" 'Next: run the migration' "$out"
assert "AE1: and the auto entry after it" 'Since this checkpoint.*wb down \(auto\)' "$(tr '\n' ' ' <<< "$out")"
assert "AE1: with the stale-plan instruction" 'plan may be stale' "$out"
assert "the clear start says to state the time and wait" 'Picked up the checkpoint from 2026-10-02 14:02.*Then wait' "$(tr '\n' ' ' <<< "$out")"

old="$(wb_epoch_to_date "$(( $(date +%s) - 30 * 3600 ))" '+%Y-%m-%d %H:%M')"
printf -- '---\nstatus: doing\n---\n# Pick\n\n## Handoffs\n\n### %s — checkpoint\n\nNext: y\n\n### %s — wb done (auto)\n\nWorktree removed.\n' "$old" "$old" > "$f"
out="$(start clear | ctx)"
assert "a 30-hour-old checkpoint has its age stated" '\(30 hours ago\)' "$out"
assert "a done entry after it is in the gap list" 'wb done \(auto\)' "$out"

assert_eq "a startup with no marker emits nothing" "" "$(start startup)"
mkdir -p "$WB_STATE_DIR/pickup"; echo wait > "$WB_STATE_DIR/pickup/proj--pick"
out="$(start startup | ctx)"
assert "a startup with a marker gets the checkpoint" 'Next: y' "$out"
assert_eq "and the marker is consumed" no "$([ -e "$WB_STATE_DIR/pickup/proj--pick" ] && echo yes || echo no)"
echo start > "$WB_STATE_DIR/pickup/proj--pick"
out="$(start startup | ctx)"
assert "a marker from /handoff new says to start without asking" 'Start on the Next step now, without asking' "$out"
assert_eq "and has no wait instruction" 0 "$(grep -c 'Then wait' <<< "$out")"

assert_eq "a compact start emits nothing" "" "$(start compact)"
assert_eq "a resume start emits nothing" "" "$(start resume)"

big="$(head -c 12000 /dev/zero | tr '\0' 'x')"
printf -- '---\nstatus: doing\n---\n# Pick\n\n## Handoffs\n\n### 2026-10-02 14:02 — checkpoint\n\n%s\n' "$big" > "$f"
out="$(start clear | ctx)"
assert "a long checkpoint is trimmed under the 10,000-character cap" '^[0-9]{4}$' "${#out}"
assert "and names the task file to read the rest" "Trimmed\. The full entry is in $f" "$out"

# --- background sessions, no pane ------------------------------------------------------
g="$TASKS_DIR/proj--bgtask.md"
printf -- '---\nstatus: doing\n---\n# Bg\n\n## Handoffs\n\n### 2026-10-02 14:02 — checkpoint\n\nNext: bg work\n' > "$g"
fake_bg 424242 idle sid-bg job1 /code/proj
jq '.name = "proj--bgtask"' "$CLAUDE_SESSIONS_DIR/424242.json" > "$T/r.json" && mv "$T/r.json" "$CLAUDE_SESSIONS_DIR/424242.json"
echo wait > "$WB_STATE_DIR/pickup/proj--bgtask"
P="" out="$(P="" start startup sid-bg | ctx)"
assert "with no pane, the registry name finds the task and its marker" 'Next: bg work' "$out"

# --- AE6: outside a wb task -----------------------------------------------------------------
out="$(P="" start clear nobody; echo "exit=$?")"
assert_eq "AE6: no pane and no registry match exits 0 silently" exit=0 "$out"
tmux new-session -d -s plain "sleep 300"
out="$(P="$(tmux list-panes -t "=plain:" -F '#{pane_id}')" start clear; echo "exit=$?")"
assert_eq "AE6: a pane in a session with no @task exits 0 silently" exit=0 "$out"

finish
