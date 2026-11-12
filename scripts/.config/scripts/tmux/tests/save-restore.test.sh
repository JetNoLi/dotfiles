#!/usr/bin/env bash
# save-restore.sh — wb save snapshots every session and its Claude panes;
# wb restore rebuilds them after a restart with each conversation resumed.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e

fake_claude_bin
export WB_SAVE_DIR="$T/saves"
mkdir -p "$T/code/proj" "$T/code/other"

# Session "work": a Claude pane plus a second window split in two.
read -r pane1 pid1 < <(fake_claude_pane work)
registry "$pid1" idle "$pane1" interactive "" sid-work "" "$T/code/proj"
tmux new-window -d -t "=work:" -n notes -c "$T/code/other"
tmux split-window -d -h -t "=work:notes" -c "$T/code/proj"
tmux set-option -t "=work:" @task "$T/tasks/proj--work.md" >/dev/null
tmux set-option -t "=work:" @wb_repo proj >/dev/null
# Session "bg": a pane attached to a background session.
tmux new-session -d -s bg -x 120 -y 30 "bash -c '(exec -a \"claude attach job12345\" sleep 300) & wait'"
fake_bg 616161 idle sid-bg job12345 "$T/code/other"
wait_until 3 sh -c "pgrep -f 'claude attach job12345' >/dev/null"

wins_before="$(tmux list-windows -t "=work:" -F '#{window_index} #{window_name}')"
out="$(cmd_save)"
assert "save reports the sessions and Claude panes" "2 sessions, 2 Claude panes" "$out"
snap="$WB_SAVE_DIR/latest.tsv"
assert "the Claude pane is saved with its session id and cwd" $'\tclaude\tsid-work\t'"$T/code/proj" "$(cat "$snap")"
assert "the attached pane is saved with its job" $'\tattach\tsid-bg\t'"$T/code/other"$'\t\tjob12345' "$(cat "$snap")"
assert_eq "save arms the automatic save" 1 "$(tmux show -gv @wb_autosave)"
n="$(ls "$WB_SAVE_DIR"/2*.tsv | wc -l | tr -d ' ')"
cmd_save --auto
assert_eq "an automatic save soon after does nothing" "$n" "$(ls "$WB_SAVE_DIR"/2*.tsv | wc -l | tr -d ' ')"
touch_epoch 1000000000 "$snap"
cmd_save --auto
assert_eq "an unchanged automatic save adds no file" "$n" "$(ls "$WB_SAVE_DIR"/2*.tsv | wc -l | tr -d ' ')"

# A restart: every session and process is gone.
tmux kill-server
rm -f "$CLAUDE_SESSIONS_DIR"/*.json; : > "$T/ps-extra"; : > "$T/claude.log"
WB_REG_LOADED=""; WB_PS_LOADED=""; WB_REG_ROWS=(); WB_REG_BY_SID=(); WB_REG_BY_JOB=(); WB_REG_BY_PANE=()
tmux new-session -d -s scratch

out="$(cmd_restore)"
assert "restore reports what it rebuilt" "2 sessions rebuilt, 2 Claude conversations resumed" "$out"
assert_eq "windows come back at their indices with their names" "$wins_before" \
  "$(tmux list-windows -t "=work:" -F '#{window_index} #{window_name}')"
assert_eq "the split window has both panes" 2 "$(tmux list-panes -t "=work:notes" | wc -l | tr -d ' ')"
assert_eq "session options come back" "$T/tasks/proj--work.md" "$(tmux show -t "=work:" -v @task)"
wait_until 5 grep -q 'resume sid-bg' "$T/claude.log"
assert "the Claude pane resumes its conversation" "^--resume sid-work$" "$(cat "$T/claude.log")"
assert "a background session with no live job resumes in its pane" "^--resume sid-bg$" "$(cat "$T/claude.log")"

out="$(cmd_restore 2>&1)"
assert "a second restore leaves open sessions alone" "0 sessions rebuilt, 0 Claude conversations resumed, 2 already open" "$out"

# A conversation still live elsewhere isn't resumed twice.
tmux kill-session -t "=work"
registry "$$" idle "" interactive "" sid-work
WB_REG_LOADED=""; WB_PS_LOADED=""
out="$(cmd_restore 2>&1)"
assert "a live conversation is not resumed again" "sid-work is already running" "$out"

finish
