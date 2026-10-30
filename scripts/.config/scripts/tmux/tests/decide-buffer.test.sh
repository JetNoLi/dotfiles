#!/usr/bin/env bash
# wb decide-buffer, decide-open and decide-clear on the private socket.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e
wb() { "$BASH" "$WB" "$@"; }
NY="$WB_STATE_DIR/needs-you/proj--dec"

# A fake nvim: answers the file, then closes after WB_TEST_NVIM_SECS.
printf '#!/usr/bin/env bash\necho "answered" >> "$1"\nsleep "${WB_TEST_NVIM_SECS:-1}"\n' > "$T/bin/nvim"
chmod +x "$T/bin/nvim"

f="$TASKS_DIR/proj--dec.md"
printf -- '---\nstatus: doing\n---\n# Dec\n\n## Handoffs\n\n## Decisions\n' > "$f"
tmux new-session -d -s proj--dec -x 160 -y 40 "sleep 300"
tmux set-option -t "=proj--dec:" @task "$f" >/dev/null
P="$(tmux list-panes -t "=proj--dec:" -F '#{pane_id}')"

ans="$(TMUX_PANE="$P" wb decide-path)"
assert "decide-path gives a fresh file under the task's state dir" "^$WB_STATE_DIR/decide/proj--dec/[0-9-]+\.md$" "$ans"
echo "Q1: yes or no?" > "$ans"

TMUX_PANE="$P" WB_TEST_NVIM_SECS=2 wb decide-buffer "$ans" > "$T/out" 2>&1 &
waiter=$!
sleep 1
assert_eq "it opens a split in the task's session" 2 "$(tmux list-panes -t "=proj--dec:" | wc -l | tr -d ' ')"
assert_eq "and marks the task as needing Jet" "buffer $ans" "$(cat "$NY" 2>/dev/null)"
assert_eq "it's still waiting while the split is open" yes "$(kill -0 "$waiter" 2>/dev/null && echo yes || echo no)"
wait "$waiter"; code=$?
assert_eq "it exits 0 once the split closes" 0 "$code"
assert_eq "printing the answer file" "$ans" "$(cat "$T/out")"
assert "whose answers are there" 'answered' "$(cat "$ans")"
assert_eq "the split is gone" 1 "$(tmux list-panes -t "=proj--dec:" | wc -l | tr -d ' ')"

TMUX_PANE="$P" wb decide-open page https://claude.ai/artifact/x
echo "Use A." | TMUX_PANE="$P" wb decision "First"
assert_eq "one recorded decision leaves the needs-you file" 2 "$(wc -l < "$NY" | tr -d ' ')"
TMUX_PANE="$P" wb decide-clear "$ans"
assert_eq "clearing the buffer keeps the page open" "page https://claude.ai/artifact/x" "$(cat "$NY")"
TMUX_PANE="$P" wb decide-clear https://claude.ai/artifact/x
assert_eq "clearing the last surface removes the file" no "$([ -e "$NY" ] && echo yes || echo no)"

TMUX_PANE="$P" wb decide-open page https://claude.ai/artifact/y
out="$(echo 'Next: z' | TMUX_PANE="$P" wb checkpoint >/dev/null; TMUX_PANE="$P" wb pickup)"
assert "pickup lists the open surfaces after the checkpoint" 'Open /decide surfaces waiting on Jet == page https://claude.ai/artifact/y' "$(tr '\n' ' ' <<< "$out" | tr -s ' ')"
TMUX_PANE="$P" wb decide-clear --all
assert_eq "decide-clear --all removes the file" no "$([ -e "$NY" ] && echo yes || echo no)"

# --- outside a task ----------------------------------------------------------------------
tmux new-session -d -s plain "sleep 300"
Q="$(tmux list-panes -t "=plain:" -F '#{pane_id}')"
out="$(TMUX_PANE="$Q" wb decide-buffer "$ans" 2>&1)"; code=$?
assert_eq "with no task for the session it refuses" 1 "$code"
assert "and says so" 'no task' "$out"
assert_eq "opening nothing" 1 "$(tmux list-panes -t "=plain:" | wc -l | tr -d ' ')"

finish
