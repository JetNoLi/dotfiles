# compat.sh — shims for what macOS lacks or spells differently: flock,
# timeout, GNU date/stat. Each tries the BSD form first, then GNU, so the
# module still runs on Linux. Sourced by wb; defines functions only.

WB_STATE_DIR="${WB_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/wb}"
WB_LOCK_WAIT="${WB_LOCK_WAIT:-5}"   # seconds a writer waits for a held task lock

# --- task locks (KTD4) -------------------------------------------------------
# One lock directory per task file, named from its basename so two paths to
# the same task share a lock. mkdir is atomic on both platforms; the pid file
# inside lets a later writer take over a lock whose holder died, so a verb
# that exits mid-write needs no cleanup trap.

_wb_lock_path() {
  printf '%s/locks/%s.lock\n' "$WB_STATE_DIR" "$(basename -- "$1")"
}

# wb_lock_acquire <task_file> [wait_seconds] — 0 once held, 75 on timeout.
wb_lock_acquire() {
  local lock waited=0 holder wait="${2:-$WB_LOCK_WAIT}"
  lock="$(_wb_lock_path "$1")"
  mkdir -p "${lock%/*}" || return 75
  while ! mkdir "$lock" 2>/dev/null; do
    holder="$(cat "$lock/pid" 2>/dev/null)"
    if [ -n "$holder" ] && ! kill -0 "$holder" 2>/dev/null; then
      rm -rf "$lock"
      continue
    fi
    if [ "$waited" -ge $(( wait * 10 )) ]; then
      echo "wb: $(basename -- "$1") is locked by pid ${holder:-?}; try again, or remove $lock if that process is gone" >&2
      return 75
    fi
    sleep 0.1
    waited=$(( waited + 1 ))
  done
  echo "$BASHPID" > "$lock/pid"
}

# wb_lock_release <task_file> — drops the lock only if this process holds it.
wb_lock_release() {
  local lock; lock="$(_wb_lock_path "$1")"
  [ "$(cat "$lock/pid" 2>/dev/null)" = "$BASHPID" ] && rm -rf "$lock"
  return 0
}

# --- time -------------------------------------------------------

# wb_epoch_to_date <epoch> [+format] — `date -r` (BSD), then `date -d @` (GNU).
wb_epoch_to_date() {
  local fmt="${2:-+%Y-%m-%d}"
  date -r "$1" "$fmt" 2>/dev/null || date -d "@$1" "$fmt"
}

# wb_date_to_epoch <"YYYY-MM-DD HH:MM"> — local time as epoch seconds:
# `date -j -f` (BSD), then `date -d` (GNU).
wb_date_to_epoch() {
  date -j -f '%Y-%m-%d %H:%M' "$1" +%s 2>/dev/null || date -d "$1" +%s
}

# wb_mtime <file> — modification time as epoch seconds. Output is captured
# first because GNU stat treats `-f %m` as two files and prints one of them.
wb_mtime() {
  local out
  if out="$(stat -f %m "$1" 2>/dev/null)"; then
    printf '%s\n' "$out"
  else
    stat -c %Y "$1"
  fi
}

# wb_watchdog <seconds> <cmd...> — run cmd, killing it after <seconds>.
# Exit status and output pass through; a killed command exits 124, as GNU
# timeout does. The command runs in its own process group and the whole
# group is killed, so a child holding stdout open can't keep a $(...) waiting.
wb_watchdog() {
  local secs="$1"; shift
  perl -e '
    $secs = shift;
    $pid = fork // exit 127;
    if (!$pid) { setpgrp(0, 0); exec @ARGV or exit 127 }
    $SIG{ALRM} = sub { kill "TERM", -$pid; exit 124 };
    alarm $secs;
    waitpid $pid, 0;
    exit($? & 127 ? 128 + ($? & 127) : $? >> 8);
  ' "$secs" "$@"
}

# wb_detach <cmd...> — run cmd in its own session, outside the caller's
# process group, so it outlives whatever started it (setsid via perl).
wb_detach() {
  nohup perl -MPOSIX -e 'POSIX::setsid(); exec @ARGV or exit 127' "$@" >/dev/null 2>&1 &
}

# wb_reverse <file> — the file's lines last first (tac, else BSD tail -r).
wb_reverse() {
  if command -v tac >/dev/null 2>&1; then tac "$1"; else tail -r "$1"; fi
}

# wb_tsv_split <line> <array_name> — split on tabs keeping empty fields,
# which `IFS=$'\t' read` collapses because tab is IFS whitespace.
wb_tsv_split() {
  local -n _wb_tsv_out="$2"
  local _wb_tsv_rest="$1"
  _wb_tsv_out=()
  while [[ "$_wb_tsv_rest" == *$'\t'* ]]; do
    _wb_tsv_out+=("${_wb_tsv_rest%%$'\t'*}")
    _wb_tsv_rest="${_wb_tsv_rest#*$'\t'}"
  done
  _wb_tsv_out+=("$_wb_tsv_rest")
}
