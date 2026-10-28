#!/usr/bin/env bash
# status.sh — registry first, markers on top, pane scraping as the fallback.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e

# fake_claude_pane <session> [argv0] — a tmux session whose pane shell runs a
# child with argv[0] "claude" (or argv0), the shape a real Claude pane has.
# Prints "<pane_id> <claude_pid>".
fake_claude_pane() {
  tmux new-session -d -s "$1" -x 120 -y 30 "bash -c '(exec -a \"${2:-claude}\" sleep 300) & wait'"
  local pane ppid cpid=""
  pane="$(tmux list-panes -t "=$1:" -F '#{pane_id}')"
  ppid="$(tmux list-panes -t "=$1:" -F '#{pane_pid}')"
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    cpid="$(pgrep -P "$ppid" | head -n1)"
    [ -n "$cpid" ] && break
    sleep 0.1
  done
  echo "$pane $cpid"
}

# registry <pid> <status> [pane] [kind] [procStart] [sessionId] [jobId]
registry() {
  local start="${5:-$(TZ=UTC LC_ALL=C ps -o lstart= -p "$1" 2>/dev/null | sed 's/ *$//')}"
  jq -n --arg pid "$1" --arg st "$2" --arg pane "${3:-}" --arg kind "${4:-interactive}" \
        --arg start "$start" --arg sid "${6:-sid-$1}" --arg job "${7:-}" '
    {pid: ($pid | tonumber), sessionId: $sid, status: $st, kind: $kind,
     procStart: $start, cwd: "/code/proj", name: "n-\($pid)"}
    + (if $pane == "" then {} else {tmux: "s:@1.\($pane)"} end)
    + (if $job == "" then {} else {jobId: $job} end)' > "$CLAUDE_SESSIONS_DIR/$1.json"
}

status_of() { # <pane_id> — the status wb gives that pane
  wb_claude_panes | awk -F'\t' -v p="$1" '$5 == p { print $3 }'
}

read -r pane1 pid1 < <(fake_claude_pane one)

registry "$pid1" waiting "$pane1"
assert_eq "AE1: registry waiting gives needs you" needs-input "$(status_of "$pane1")"
registry "$pid1" busy "$pane1"
assert_eq "registry busy gives working" working "$(status_of "$pane1")"
registry "$pid1" idle "$pane1"
assert_eq "registry idle gives idle" idle "$(status_of "$pane1")"
registry "$pid1" frobbing "$pane1"
assert_eq "an unknown registry status gives idle" idle "$(status_of "$pane1")"
assert "the pane row carries the registry's session id" "sid-$pid1" "$(wb_claude_panes)"

# A spinner title makes the scrape fallback say working, so a registry entry
# that is ignored shows up as "working" rather than its own status.
tmux select-pane -t "$pane1" -T "⠋ thinking"
rm -f "$CLAUDE_SESSIONS_DIR"/*.json
registry 999999 waiting "$pane1"
assert_eq "an entry whose pid is dead is ignored" working "$(status_of "$pane1")"
registry "$pid1" waiting "$pane1" interactive "Mon Jan  1 00:00:00 2001"
assert_eq "an entry whose pid was reused (procStart differs) is ignored" working "$(status_of "$pane1")"

rm -f "$CLAUDE_SESSIONS_DIR"/*.json
printf '{"pid": %s, "status": "wai' "$pid1" > "$CLAUDE_SESSIONS_DIR/0-half.json"
registry "$pid1" waiting "$pane1"
assert_eq "a half-written file is skipped and later entries still load" needs-input "$(status_of "$pane1")"
rm -f "$CLAUDE_SESSIONS_DIR/0-half.json"

# --- markers ---------------------------------------------------------------------
registry "$pid1" idle "$pane1"
tmux set -p -t "$pane1" @claude_blocked nvim-buffer
assert_eq "AE3: an nvim decision buffer over registry idle gives needs you" needs-input "$(status_of "$pane1")"
tmux set -p -t "$pane1" @claude_blocked done
assert_eq "the done marker gives finished" done "$(status_of "$pane1")"
tmux set -pu -t "$pane1" @claude_blocked

# --- fallback ----------------------------------------------------------------------
out="$(CLAUDE_SESSIONS_DIR="$T/no-such-dir" status_of "$pane1")"
assert_eq "AE2: with no registry, the pane still gets a status from scraping" working "$out"
tmux select-pane -t "$pane1" -T "host.local"
assert_eq "a plain-text title scrapes as idle" idle "$(CLAUDE_SESSIONS_DIR="$T/no-such-dir" status_of "$pane1")"

tmux new-session -d -s plain "sleep 300"
assert_eq "a pane with no claude process isn't listed" 0 "$(wb_claude_panes | cut -f2 | grep -c '^plain:')"

# --- background sessions ---------------------------------------------------------------
# The real registry form, with a start time stubbed into ps for a pid that
# doesn't exist on this machine.
cat > "$T/bin/ps" <<EOF
#!/usr/bin/env bash
/bin/ps "\$@"
case "\$*" in *lstart=,command=*) echo "424242     1 Sun Oct  5 17:48:10 2026 claude" ;; esac
EOF
chmod +x "$T/bin/ps"
registry 424242 busy "" bg "Sun Oct  5 17:48:10 2026" 86e34592-cdb9-4da2-bf55-6db85f3bc22e 86e34592
out="$(wb_bg_sessions)"
assert "an entry in the registry's real procStart form is accepted" '^86e34592-cdb9' "$out"
assert "a background session comes back with its job id, cwd and status" \
  $'86e34592\tn-424242\t/code/proj\tworking\t$' "$out"

read -r pane2 pid2 < <(fake_claude_pane two "claude attach 86e34592")
out="$(wb_bg_sessions)"
assert "a pane running claude attach is the session's attached target" $'\ttwo:[0-9]+\\.[0-9]+$' "$out"
assert_eq "the attached pane takes the background session's status" working "$(status_of "$pane2")"

registry "$pid1" idle ""
assert "an interactive session with no tmux pane is not a background session (AE5)" \
  '^1$' "$(wb_bg_sessions | wc -l | tr -d ' ')"

assert_eq "wb down's primary id comes from the registry entry for the pane" \
  "sid-$pid2" "$(registry "$pid2" idle "$pane2"; wb_registry_pane_session_id "$pane2")"

finish
