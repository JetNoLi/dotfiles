# helpers.sh — shared harness for wb tests: asserts, fixture dirs, and a
# throwaway tmux server. Sourced by each *.test.sh; never touches the real
# ~/tasks, ~/.claude or tmux server.

WB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/wb"
FIXTURES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/fixtures"
T="$(mktemp -d -t wb-test.XXXXXX)"
mkdir -p "$T/bin" "$T/tasks" "$T/projects" "$T/sessions" "$T/state"
export TASKS_DIR="$T/tasks"
export CLAUDE_PROJECTS_DIR="$T/projects"
export CLAUDE_SESSIONS_DIR="$T/sessions"
export WB_STATE_DIR="$T/state"
export WB_REPO_ROOTS="$T/code"

# Every `tmux` call in a test, including the module's own, goes to a private
# socket.
SOCK="wb-test-$$"
REAL_TMUX="$(command -v tmux)"
printf '#!/usr/bin/env bash\nexec "%s" -L "%s" "$@"\n' "$REAL_TMUX" "$SOCK" > "$T/bin/tmux"
chmod +x "$T/bin/tmux"
PATH="$T/bin:$PATH"

# `ps` passes through, plus any fake process lines a test adds to
# $T/ps-extra for the process table status.sh reads.
: > "$T/ps-extra"
printf '#!/usr/bin/env bash\n/bin/ps "$@"\ncase "$*" in *lstart=,command=*) cat "%s" ;; esac\n' "$T/ps-extra" > "$T/bin/ps"
chmod +x "$T/bin/ps"

cleanup() {
  "$REAL_TMUX" -L "$SOCK" kill-server 2>/dev/null || true
  rm -rf "$T"
}
trap cleanup EXIT

fail=0
assert() { # <desc> <expected-regex> <actual>
  if printf '%s' "$3" | grep -qE -- "$2"; then
    echo "ok   - $1"
  else
    echo "FAIL - $1"
    echo "       expected match: $2"
    echo "       got: $(printf '%s' "$3" | head -8)"
    fail=1
  fi
}
assert_eq() { # <desc> <expected> <actual>
  if [ "$2" = "$3" ]; then
    echo "ok   - $1"
  else
    echo "FAIL - $1 (expected '$2', got '$3')"
    fail=1
  fi
}
finish() { exit "$fail"; }

# make_repo <path> — a git repo with one commit.
make_repo() {
  mkdir -p "$1"
  git init -q "$1"
  git -C "$1" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
}

# touch_epoch <epoch> <file> — set a file's mtime; `touch -d` is GNU only.
touch_epoch() {
  TZ=UTC touch -t "$(TZ=UTC wb_epoch_to_date "$1" +%Y%m%d%H%M.%S)" "$2"
}

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

# registry <pid> <status> [pane] [kind] [procStart] [sessionId] [jobId] [cwd]
# — a session registry file. procStart defaults to the pid's real start.
registry() {
  local start="${5:-$(TZ=UTC LC_ALL=C /bin/ps -o lstart= -p "$1" 2>/dev/null | sed 's/ *$//')}"
  jq -n --arg pid "$1" --arg st "$2" --arg pane "${3:-}" --arg kind "${4:-interactive}" \
        --arg start "$start" --arg sid "${6:-sid-$1}" --arg job "${7:-}" --arg cwd "${8:-/code/proj}" '
    {pid: ($pid | tonumber), sessionId: $sid, status: $st, kind: $kind,
     procStart: $start, cwd: $cwd, name: "n-\($pid)"}
    + (if $pane == "" then {} else {tmux: "s:@1.\($pane)"} end)
    + (if $job == "" then {} else {jobId: $job} end)' > "$CLAUDE_SESSIONS_DIR/$1.json"
}

# fake_bg <pid> <status> <sessionId> <jobId> <cwd> — a background session
# the registry lists, with a fake process-table line so it reads as live.
fake_bg() {
  echo "$1     1 Sun Oct  5 17:48:10 2026 claude" >> "$T/ps-extra"
  registry "$1" "$2" "" bg "Sun Oct  5 17:48:10 2026" "$3" "$4" "$5"
}
