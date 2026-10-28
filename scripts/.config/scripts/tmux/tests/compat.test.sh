#!/usr/bin/env bash
# compat.sh shims and the bash 5 guard.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e

# --- bash 5 guard -------------------------------------------------------------
out="$(/bin/bash "$WB" help 2>&1)"; code=$?
assert "bash 3.2 is refused with an install hint" 'brew install bash' "$out"
assert "bash 3.2 exits non-zero" '^[1-9]' "$code"
out="$("$BASH" "$WB" help 2>&1)"; code=$?
assert_eq "bash 5 runs wb help" 0 "$code"

# --- locks --------------------------------------------------------------------
task="$T/tasks/proj--locked.md"
lib="$(dirname "$WB")/wb-lib/compat.sh"
start=$SECONDS
"$BASH" -c "source '$lib'; wb_lock_acquire '$task' && sleep 1.5 && wb_lock_release '$task'" &
sleep 0.3
"$BASH" -c "source '$lib'; wb_lock_acquire '$task' 5"; code=$?
wait
assert_eq "a second writer gets the lock once the first releases" 0 "$code"
assert "the second writer waited for the first" '^[1-9]' "$(( SECONDS - start ))"

"$BASH" -c "source '$lib'; wb_lock_acquire '$task' && sleep 3" &
holder=$!
sleep 0.3
out="$("$BASH" -c "source '$lib'; wb_lock_acquire '$task' 0" 2>&1)"; code=$?
assert_eq "a live holder makes a no-wait acquire fail" 75 "$code"
assert "the refusal names the holder pid" "pid $holder" "$out"
kill "$holder" 2>/dev/null; wait "$holder" 2>/dev/null

# The killed holder left its lock dir behind with a dead pid in it.
assert "the killed holder's lock is still on disk" 'pid' "$(ls "$(_wb_lock_path "$task")")"
"$BASH" -c "source '$lib'; wb_lock_acquire '$task' 0"; code=$?
assert_eq "a lock held by a dead pid is taken over at once" 0 "$code"

# --- watchdog -----------------------------------------------------------------
start=$SECONDS
wb_watchdog 1 sleep 5; code=$?
assert_eq "the watchdog kills a slow command with exit 124" 124 "$code"
assert "the watchdog stops it near the limit" '^[12]$' "$(( SECONDS - start ))"
out="$(wb_watchdog 2 sh -c 'echo fast; exit 3')"; code=$?
assert_eq "a fast command's output passes through" fast "$out"
assert_eq "a fast command's exit code passes through" 3 "$code"

# --- dates and mtimes ------------------------------------------------------------
# Expected values are what GNU `date -d @1793186805` and `stat -c %Y` give.
assert_eq "epoch to date" "2026-10-28 11:26:45" "$(TZ=UTC wb_epoch_to_date 1793186805 '+%Y-%m-%d %H:%M:%S')"
assert_eq "epoch to date, default format" "2026-10-28" "$(TZ=UTC wb_epoch_to_date 1793186805)"
touch_epoch 1793186805 "$T/f"
assert_eq "mtime" 1793186805 "$(wb_mtime "$T/f")"

# --- field splitter -----------------------------------------------------------------
wb_tsv_split $'a\t\tc\t' fields
assert_eq "empty middle and trailing fields are kept" 4 "${#fields[@]}"
assert_eq "the empty middle field is empty" "" "${fields[1]}"
assert_eq "the last real field" c "${fields[2]}"

finish
