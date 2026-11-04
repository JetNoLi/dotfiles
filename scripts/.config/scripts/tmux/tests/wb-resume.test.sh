#!/usr/bin/env bash
# Resuming DORMANT tasks (AE6) and attaching to background sessions (R8).
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e
fake_claude_bin
printf '#!/usr/bin/env bash\necho "[]"\n' > "$T/bin/gh"; chmod +x "$T/bin/gh"
wb() { "$BASH" "$WB" "$@"; }
make_repo "$T/code/dotfiles"
REPO="$T/code/dotfiles"

# --- AE6: resume a parked task ---------------------------------------------------------------
wb new dotfiles parked >/dev/null 2>&1
WT="$REPO/.worktrees/parked"
mkdir -p "$(wb_transcript_dir "$WT")"
echo '{"parentUuid":"x","timestamp":"2026-10-28T10:00:00.000Z"}' > "$(wb_transcript_dir "$WT")/conv-1.jsonl"
wb down dotfiles--parked >/dev/null 2>&1
task="$TASKS_DIR/dotfiles--parked.md"
assert "the parked task is on DORMANT" 'parked' "$(collect_dormant_rows normal | cut -f2)"

: > "$T/claude.log"
out="$(wb resume dotfiles--parked 2>&1)"; code=$?
assert_eq "wb resume succeeds" 0 "$code"
assert_eq "it rebuilds the session" "nvim agent shell" "$(tmux list-windows -t =dotfiles--parked: -F '#{window_name}' | xargs)"
assert "it types claude --resume for the last conversation" 'claude --resume conv-1' \
  "$(tmux capture-pane -p -t =dotfiles--parked:agent)"
assert_eq "it doesn't run it" "" "$(cat "$T/claude.log")"
assert "it records the resume" 'wb resume \(auto\)' "$(cat "$task")"

# --- Enter on a background row, twice -----------------------------------------------------------
wb new --bg dotfiles bg-task >/dev/null 2>&1
btask="$TASKS_DIR/dotfiles--bg-task.md"
: > "$T/focus.log"; : > "$T/claude.log"
wb_bg_attach 86e34592 "$btask"
wait_until 5 grep -q '^attach' "$T/claude.log"
assert "the first Enter attaches in the task session's agent window" '^attach 86e34592$' "$(cat "$T/claude.log")"
assert "and goes there" 'dotfiles--bg-task' "$(cat "$T/focus.log")"
windows="$(tmux list-windows -t =dotfiles--bg-task: -F '#{window_name}' | xargs)"
: > "$T/focus.log"
( wb_bg_attach 86e34592 "$btask" )
sleep 0.3
assert_eq "the second Enter starts no second attach" 1 "$(grep -c attach "$T/claude.log")"
assert "it jumps to the attached pane" 'dotfiles--bg-task' "$(cat "$T/focus.log")"
assert_eq "and opens no new window" "$windows" "$(tmux list-windows -t =dotfiles--bg-task: -F '#{window_name}' | xargs)"

# --- a session Jet renamed ---------------------------------------------------------------------
tmux kill-session -t =dotfiles--bg-task
tmux new-session -d -s dotfiles--bg-task -c "$T" "sleep 300"
tmux set -t =dotfiles--bg-task: @task "$btask"
tmux rename-session -t =dotfiles--bg-task mine
: > "$T/focus.log"; : > "$T/claude.log"
wb_bg_attach 86e34592 "$btask"
wait_until 5 grep -q '^attach' "$T/claude.log"
assert "Enter on a bg row attaches in the renamed session" '^attach 86e34592$' "$(cat "$T/claude.log")"
assert "and goes there" '^.*mine' "$(cat "$T/focus.log")"
assert_eq "it opens no stray bg- window elsewhere" "" "$(tmux list-windows -a -F '#{window_name}' | grep '^bg-')"
wb resume dotfiles--bg-task >/dev/null 2>&1
assert_eq "wb resume reuses the renamed session instead of making a second one" "" \
  "$(tmux list-sessions -F '#S' | grep -x dotfiles--bg-task)"

finish
