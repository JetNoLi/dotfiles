#!/usr/bin/env bash
# wb down, through the real CLI.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e
fake_claude_bin
wb() { "$BASH" "$WB" "$@"; }
make_repo "$T/code/dotfiles"
REPO="$T/code/dotfiles"

# fake_gh <body> — a gh on PATH running <body>.
fake_gh() { printf '#!/usr/bin/env bash\n%s\n' "$1" > "$T/bin/gh"; chmod +x "$T/bin/gh"; }
fake_gh 'echo "[]"'

# --- AE7: parking a background task ------------------------------------------------------
wb new --bg dotfiles bg-task >/dev/null 2>&1
WT="$REPO/.worktrees/bg-task"
mkdir -p "$(wb_transcript_dir "$WT")"
echo '{"parentUuid":"x","timestamp":"2026-10-28T10:00:00.000Z"}' > "$(wb_transcript_dir "$WT")/86e34592-cdb9-4da2-bf55-6db85f3bc22e.jsonl"
mkdir -p "$WB_STATE_DIR/needs-you"; echo "page https://claude.ai/artifact/x" > "$WB_STATE_DIR/needs-you/dotfiles--bg-task"
out="$(wb down dotfiles--bg-task 2>&1)"; code=$?
assert_eq "wb down on a --bg task succeeds" 0 "$code"
assert_eq "it stops showing the task as needing Jet" no "$([ -e "$WB_STATE_DIR/needs-you/dotfiles--bg-task" ] && echo yes || echo no)"
assert "it stops the background session by its short id" '^stop 86e34592$' "$(cat "$T/claude.log")"
assert_eq "it kills the tmux session" "" "$(tmux list-sessions -F '#S' 2>/dev/null | grep bg-task)"
assert "it keeps the worktree" 'bg-task' "$(git -C "$REPO" worktree list)"
assert "the record keeps the bg session as @primary" '^86e34592-[^@]*@[^@]*@primary$' \
  "$(wb_task_get "$TASKS_DIR/dotfiles--bg-task.md" claude_sessions)"
assert "AE7: the task appears on DORMANT" $'^dotfiles\tbg task\t' "$(collect_dormant_rows normal)"

# --- a background agent that won't stop ------------------------------------------------------
wb new --bg dotfiles stuck >/dev/null 2>&1
sessions="$(wb_task_get "$TASKS_DIR/dotfiles--stuck.md" claude_sessions)"
out="$(WB_TEST_STOP_FAILS=1 wb down dotfiles--stuck 2>&1)"; code=$?
assert_eq "a failed stop aborts wb down" 1 "$code"
assert "it says the agent is still running" 'still running' "$out"
assert "the tmux session is kept" 'dotfiles--stuck' "$(tmux list-sessions -F '#S')"
assert_eq "the record is unchanged" "$sessions" "$(wb_task_get "$TASKS_DIR/dotfiles--stuck.md" claude_sessions)"

# --- @primary from the registry for a foreground agent ---------------------------------------
wb new dotfiles fg-task >/dev/null 2>&1
WT2="$REPO/.worktrees/fg-task"
tmux respawn-pane -k -t =dotfiles--fg-task:agent "bash -c '(exec -a claude sleep 300) & wait'"
sleep 0.3
pane="$(tmux display -p -t =dotfiles--fg-task:agent '#{pane_id}')"
cpid="$(pgrep -P "$(tmux display -p -t "$pane" '#{pane_pid}')" | head -n1)"
registry "$cpid" idle "$pane" interactive "" live-sid "" "$WT2"
mkdir -p "$(wb_transcript_dir "$WT2")"
for id in old-sid live-sid; do echo '{}' > "$(wb_transcript_dir "$WT2")/$id.jsonl"; done
touch_epoch 1793190000 "$(wb_transcript_dir "$WT2")/old-sid.jsonl"
wb down dotfiles--fg-task >/dev/null 2>&1
assert "@primary is the session the registry reports for the agent pane" \
  'live-sid@[^,]*@primary' "$(wb_task_get "$TASKS_DIR/dotfiles--fg-task.md" claude_sessions)"
assert "older conversations are kept without the mark" 'old-sid@[^@,]*(,|$)' \
  "$(wb_task_get "$TASKS_DIR/dotfiles--fg-task.md" claude_sessions)"

# --- the PR check -------------------------------------------------------------------------
wb new dotfiles pr-task >/dev/null 2>&1
fake_gh 'echo "[{\"number\": 7}]"'
wb down dotfiles--pr-task >/dev/null 2>&1
assert_eq "an open PR moves the task to review" review "$(wb_task_get "$TASKS_DIR/dotfiles--pr-task.md" status)"

wb new dotfiles hang-task >/dev/null 2>&1
fake_gh 'sleep 30'
start=$SECONDS
out="$(WB_GH_TIMEOUT=1 wb down dotfiles--hang-task 2>&1)"; code=$?
assert_eq "wb down with gh hanging still finishes" 0 "$code"
assert "it finishes through the watchdog" '^[1-4]$' "$(( SECONDS - start ))"
assert_eq "and leaves the status unchanged" doing "$(wb_task_get "$TASKS_DIR/dotfiles--hang-task.md" status)"
fake_gh 'echo "[]"'

# --- a session Jet renamed ---------------------------------------------------------------------
wb new dotfiles renamed >/dev/null 2>&1
tmux rename-session -t =dotfiles--renamed my-name
out="$(wb down dotfiles--renamed 2>&1)"; code=$?
assert_eq "wb down by stem finds a renamed session" 0 "$code"
assert_eq "and closes it" "" "$(tmux list-sessions -F '#S' 2>/dev/null | grep -x my-name)"

finish
