#!/usr/bin/env bash
# claude-status.sh, the status-left count.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
set +e
SEG="$(dirname "$WB")/claude-status.sh"

read -r p1 c1 < <(fake_claude_pane one)
read -r p2 c2 < <(fake_claude_pane two)
registry "$c1" idle "$p1"
registry "$c2" idle "$p2"
assert_eq "with nothing needing you it prints nothing" "" "$("$BASH" "$SEG")"

registry "$c1" waiting "$p1"
tmux set -p -t "$p2" @claude_blocked done
assert_eq "it counts one needing you and one finished" \
  "#[fg=magenta,bold]✳1#[default] #[fg=cyan]✔1#[default] " "$("$BASH" "$SEG")"

fake_bg 424242 waiting bg-sid bgjob /code/proj
assert "a background session waiting on you counts too" '✳2' "$("$BASH" "$SEG")"

assert_eq "under bash 3.2 it prints nothing and exits 0" "exit=0" "$(/bin/bash "$SEG"; echo "exit=$?")"

finish
