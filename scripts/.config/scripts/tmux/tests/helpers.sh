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
