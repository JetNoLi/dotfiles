#!/usr/bin/env bash
# claude-autoclear.sh: claiming a /handoff clear request at Stop, the checks
# before a restart, and the restart itself on the private socket.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e
fake_claude_bin
wb() { "$BASH" "$WB" "$@"; }
AC="$(dirname "$WB")/claude-autoclear.sh"
NOTIFY="$(dirname "$WB")/claude-notify-hook.sh"
LOG="$WB_STATE_DIR/handoff.log"

mkdir -p "$T/code/proj/.worktrees/ac"
f="$TASKS_DIR/proj--ac.md"
printf -- '---\nstatus: doing\nrepo: proj\nrepo_path: %s\nworktree: .worktrees/ac\nclaude_sessions: old-sid@2026-10-01T00:00:00Z@primary\n---\n# Ac\n\n## Handoffs\n\n## Decisions\n' "$T/code/proj" > "$f"
echo 'Next: x' | wb checkpoint --task proj--ac >/dev/null

# Panes showing Claude's screen. The input line is ❯ and a no-break space,
# empty with a dim suggestion or holding typed text; a transcript line above
# it uses a plain space.
EMPTY="bash -c 'printf \"❯ an earlier prompt\\n\\342\\235\\257\\302\\240\\033[2mwrite it\\033[0m\\n\"; sleep 300'"
TYPED="bash -c 'printf \"❯ an earlier prompt\\n\\342\\235\\257\\302\\240half a thought\\n\"; sleep 300'"
DIALOG="bash -c 'printf \"Do you want to proceed?\\n\"; sleep 300'"
tmux new-session -d -s proj--ac -x 120 -y 30 "$EMPTY"
tmux set-option -t "=proj--ac:" @task "$f" >/dev/null
P="$(tmux list-panes -t "=proj--ac:" -F '#{pane_id}')"
screen() { tmux respawn-pane -k -t "$P" "$1"; tmux set -pu -t "$P" @claude_working; sleep 0.3; }

# stop [permission_mode] [background_tasks_json]
stop() {
  printf '{"session_id":"old-sid","permission_mode":"%s","background_tasks":%s}' "${1:-default}" "${2:-[]}" \
    | TMUX_PANE="$P" "$AC" stop
}
# wait_log <regex> — up to ~8s for the log to match.
wait_log() { wait_for "$LOG" "$1"; }
wait_for() { for _ in $(seq 40); do grep -qE -- "$2" "$1" 2>/dev/null && return 0; sleep 0.2; done; return 1; }
lines() { wc -l < "$LOG" 2>/dev/null | tr -d ' ' || echo 0; }
marker() { [ -e "$WB_STATE_DIR/clear/proj--ac" ] && echo yes || echo no; }

# --- no request --------------------------------------------------------------------
stop; sleep 0.5
assert_eq "a Stop with no request does nothing" "" "$(cat "$T/claude.log" "$LOG" 2>/dev/null)"

# --- AE3: a checkpoint alone arms nothing ------------------------------------------------
assert_eq "AE3: a checkpoint without clear-request leaves no clear request" no "$(marker)"

# --- the restart ---------------------------------------------------------------------------
wb clear-request --task proj--ac >/dev/null
assert_eq "clear-request writes the clear request" yes "$(marker)"
assert_eq "and a pick-up marker for the restart" wait "$(cat "$WB_STATE_DIR/pickup/proj--ac" 2>/dev/null)"
stop auto
assert_eq "the Stop claims the request at once" no "$(marker)"
wait_for "$T/claude.log" 'Pick up'
assert "the pane restarts Claude with the pick-up prompt in auto mode" \
  '^--permission-mode auto Pick up this task from its /handoff checkpoint\.$' "$(cat "$T/claude.log" 2>/dev/null)"
assert_eq "in the task's worktree" "$(cd "$T/code/proj/.worktrees/ac" && pwd -P)" "$(tmux display -p -t "$P" '#{pane_current_path}')"
assert "and falls back to a shell when Claude exits" '^(sh|bash)$' "$(tmux display -p -t "$P" '#{pane_current_command}')"
for _ in $(seq 20); do grep -q 'new-sid' "$f" && break; sleep 0.25; done
assert "the new session becomes @primary" '^new-sid@[^@]*@primary,old-sid@' "$(wb_task_get "$f" claude_sessions)"
# _ac_record_primary waits for the task lock; held throughout, it gives up
# and leaves the record as it was. The helper runs under the tmux server, so
# its wait comes from the server's environment.
tmux set-environment -g WB_LOCK_WAIT 1
sleep 30 & holder=$!
mkdir -p "$WB_STATE_DIR/locks/proj--ac.md.lock"; echo "$holder" > "$WB_STATE_DIR/locks/proj--ac.md.lock/pid"
before="$(wb_task_get "$f" claude_sessions)"; : > "$LOG"
screen "$EMPTY"; wb clear-request --task proj--ac >/dev/null 2>&1; stop
wait_log 'restarted the pane'; sleep 3
assert_eq "with the task locked, the new session isn't written over the record" "$before" "$(wb_task_get "$f" claude_sessions)"
kill "$holder" 2>/dev/null; wait "$holder" 2>/dev/null
tmux set-environment -gu WB_LOCK_WAIT

n="$(lines)"; : > "$T/claude.log"
stop; sleep 1
assert_eq "a second Stop finds nothing to claim" "$n" "$(lines)"
assert_eq "and restarts nothing" "" "$(cat "$T/claude.log")"

# --- default mode needs no flag ---------------------------------------------------------------
screen "$EMPTY"; : > "$LOG"; wb clear-request --task proj--ac >/dev/null; stop default
wait_for "$T/claude.log" 'Pick up'
assert "a default-mode session restarts without --permission-mode" '^Pick up this task' "$(cat "$T/claude.log")"

# --- reasons to give up -----------------------------------------------------------------------
: > "$T/claude.log"
screen "$EMPTY"; wb clear-request --task proj--ac >/dev/null
sed -i '' "s/^created=.*/created=$(( $(date +%s) - 200 ))/" "$WB_STATE_DIR/clear/proj--ac"
stop
assert "a request over 2 minutes old is discarded" 'no restart: the request was over 120 seconds old' "$(tail -n1 "$LOG")"
assert_eq "its pick-up marker goes with it" no "$([ -e "$WB_STATE_DIR/pickup/proj--ac" ] && echo yes || echo no)"

wb clear-request --task proj--ac >/dev/null
echo '{"session_id":"old-sid"}' | TMUX_PANE="$P" "$NOTIFY" start
assert_eq "a prompt sent before the Stop cancels the request" no "$(marker)"
assert "and says why in the log" 'cancelled: a prompt was sent' "$(tail -n1 "$LOG")"

# A background session has no pane, so its prompt reaches the hook without
# $TMUX_PANE; it still cancels.
mkdir -p "$T/code/proj/.worktrees/bgac"
fb="$TASKS_DIR/proj--bgac.md"
printf -- '---\nstatus: doing\nrepo: proj\nrepo_path: %s\nworktree: .worktrees/bgac\nclaude_sessions: bg-sid@2026-10-01T00:00:00Z@primary\n---\n# Bgac\n\n## Handoffs\n\n## Decisions\n' "$T/code/proj" > "$fb"
echo 'Next: y' | wb checkpoint --task proj--bgac >/dev/null
fake_bg 515151 idle bg-sid bgjob01 "$T/code/proj/.worktrees/bgac" proj--bgac
bgmarker() { [ -e "$WB_STATE_DIR/clear/proj--bgac" ] && echo yes || echo no; }
wb clear-request --session-id bg-sid >/dev/null
assert_eq "a background session's clear-request writes its request" yes "$(bgmarker)"
echo '{"session_id":"bg-sid"}' | "$NOTIFY" start
assert_eq "a prompt in a background session cancels its request too" no "$(bgmarker)"

screen "$TYPED"; : > "$LOG"; wb clear-request --task proj--ac >/dev/null; stop
wait_log "no restart"
assert "AE2: text on the input line stops the restart" "no restart: there's text on the input line" "$(tail -n1 "$LOG")"
assert "AE2: and the checkpoint is kept" '— checkpoint' "$(cat "$f")"

screen "$DIALOG"; : > "$LOG"; wb clear-request --task proj--ac >/dev/null; stop
wait_log "no restart"
assert "with no input line on screen, it doesn't restart" "no restart: Claude's input line isn't on screen" "$(tail -n1 "$LOG")"

screen "$EMPTY"; : > "$LOG"; wb clear-request --task proj--ac >/dev/null
tmux set -p -t "$P" @claude_working 1
stop; wait_log 'a new turn started'
assert "a pane marked working stops the restart" 'no restart: a new turn started' "$(tail -n1 "$LOG")"

screen "$EMPTY"; wb clear-request --task proj--ac >/dev/null; stop default '[{"id":"b1"}]'
assert "background tasks in the session stop the restart" 'no restart: background tasks are still running' "$(tail -n1 "$LOG")"

# An open buffer is a live nvim pane; any pane on the socket stands in.
tmux new-session -d -s nvimsplit "sleep 300"
N="$(tmux list-panes -t "=nvimsplit:" -F '#{pane_id}')"
mkdir -p "$WB_STATE_DIR/needs-you"; echo "buffer /tmp/answers.md $N" > "$WB_STATE_DIR/needs-you/proj--ac"
wb clear-request --task proj--ac >/dev/null; stop
assert "an open /decide buffer stops the restart" 'no restart: a /decide buffer is open' "$(tail -n1 "$LOG")"
assert_eq "no give-up path restarted anything" "" "$(cat "$T/claude.log")"

tmux kill-session -t "=nvimsplit"; : > "$LOG"
screen "$EMPTY"; wb clear-request --task proj--ac >/dev/null; stop
wait_log 'restarted the pane|no restart'
assert "a buffer whose split has closed doesn't stop it" 'restarted the pane' "$(tail -n1 "$LOG")"
rm -f "$WB_STATE_DIR/needs-you/proj--ac"; : > "$T/claude.log"

# --- a background session restarts by stop and start (KTD4) ------------------------------
# The fake's `stop` drops registry entry 515151 and `--bg` writes a new one,
# so each case lists the old session again first.
bgstop() { printf '{"session_id":"bg-sid","permission_mode":"%s","background_tasks":[]}' "${1:-default}" | "$AC" stop; }
bgsession() { fake_bg 515151 idle bg-sid bgjob01 "$T/code/proj/.worktrees/bgac" proj--bgac; }

: > "$LOG"; : > "$T/claude.log"
wb clear-request --session-id bg-sid >/dev/null; bgstop auto
wait_log 'restarted the background session|no restart'
assert "the background session is restarted" 'restarted the background session proj--bgac' "$(tail -n1 "$LOG")"
assert "by stopping its job" '^stop bgjob01$' "$(cat "$T/claude.log")"
assert "and starting it again under its name with the pick-up prompt" \
  '^--bg -n proj--bgac --permission-mode auto Pick up this task from its /handoff checkpoint\.$' "$(cat "$T/claude.log")"
assert "the new session becomes @primary" '^86e34592-cdb9-4da2-bf55-6db85f3bc22e@[^@]*@primary,bg-sid@' "$(wb_task_get "$fb" claude_sessions)"
assert_eq "the request is used up" "" "$(ls "$WB_STATE_DIR/clear" | grep bgac)"

bgsession; : > "$LOG"
tmux new-session -d -s attached "claude attach bgjob01"; sleep 0.3; : > "$T/claude.log"
wb clear-request --session-id bg-sid >/dev/null; bgstop
wait_log 'no restart'
assert "an attached client stops the restart" "no restart: you're attached to the background session bgjob01" "$(tail -n1 "$LOG")"
assert_eq "and the job isn't stopped" "" "$(cat "$T/claude.log")"
tmux kill-session -t "=attached"

bgsession; : > "$LOG"; : > "$T/claude.log"
wb clear-request --session-id bg-sid >/dev/null; WB_TEST_STOP_FAILS=1 bgstop
wait_log 'no restart'
assert "a job that won't stop isn't started again" "no restart: the background session bgjob01 wouldn't stop" "$(tail -n1 "$LOG")"
assert_eq "and nothing is started" "" "$(grep -- '--bg' "$T/claude.log")"

bgsession; : > "$LOG"; : > "$T/claude.log"
wb clear-request --session-id bg-sid >/dev/null; WB_TEST_BG_FAILS=1 bgstop
wait_log 'no restart'
assert "a job that stops but won't start says to resume it" \
  "no restart: the background session stopped but didn't start again; run wb resume" "$(tail -n1 "$LOG")"
assert_eq "and leaves no pick-up marker" no "$([ -e "$WB_STATE_DIR/pickup/proj--bgac" ] && echo yes || echo no)"

finish
