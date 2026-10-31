#!/usr/bin/env bash
# Claude Code Stop hook → the auto-clear half of /handoff (KTD2–KTD4). When
# the turn that ran `wb clear-request` ends, restart Claude in a clean context
# with a first prompt; the SessionStart pick-up hook then hands it the
# checkpoint. Nothing is typed into any pane.
#
# Wired from ~/.claude/settings.json by install.sh:
#   Stop -> claude-autoclear.sh stop
#
#   stop                           claim the task's clear request and launch
#                                  the helper detached, then exit at once
#   helper <claimed> <mode> <bin>  wait for the turn to settle, check nothing
#                                  is pending, then restart: a pane is
#                                  respawned, a background job stopped and
#                                  started again under its name
#
# Every path that doesn't restart keeps the checkpoint, drops the markers,
# logs why to $WB_STATE_DIR/handoff.log and shows it on the pane. Always
# exits 0.
set -uo pipefail

WB_CLEAR_PROMPT="${WB_CLEAR_PROMPT:-Pick up this task from its /handoff checkpoint.}"

state="${WB_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/wb}"
case "${1:-}" in
  stop) [ -n "$(ls -A "$state/clear" 2>/dev/null | grep -v '\.claimed$')" ] || exit 0 ;;
  helper) ;;
  *) exit 0 ;;
esac

AC_SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
# shellcheck source=/dev/null
source "$(dirname "$0")/wb" 2>/dev/null || exit 0
set +e +u

# _ac_give_up <stem> <claimed> <pane> <reason>
_ac_give_up() {
  rm -f "$2" "$(wb_pickup_marker "$1")"
  wb_handoff_log "$1" "no restart: $4"
  [ -z "$3" ] || tmux display-message -d 5000 -t "$3" \
    "wb: no auto-clear — $4. The checkpoint is saved; /clear picks it up." 2>/dev/null
  exit 0
}

# _ac_field <file> <key>
_ac_field() { sed -n "s/^$2=//p" "$1" 2>/dev/null | head -n1; }

# _ac_input_pending <pane> — text on Claude's input line, or no input line
# on screen (a dialog, say), when it can't tell; AC_PENDING says which. The
# input line is the ❯ followed by a no-break space; transcript lines use a
# plain space. An empty line is blank or shows a dim placeholder or
# suggestion; typed text isn't dim.
_ac_input_pending() {
  local line rest prompt=$'\xe2\x9d\xaf\xc2\xa0'
  line="$(tmux capture-pane -p -e -t "$1" 2>/dev/null | LC_ALL=C grep -F "$prompt" | tail -n1)"
  AC_PENDING="Claude's input line isn't on screen (a dialog, say)"
  [ -n "$line" ] || return 0
  AC_PENDING="there's text on the input line"
  rest="${line#*"$prompt"}"
  rest="$(LC_ALL=C sed -E $'s/\e\\[(0|39|49)?m//g; s/[[:space:]]+$//' <<< "$rest")"
  [ -n "$rest" ] && [[ "$rest" != $'\e[2m'* ]]
}

stop_hook() {
  local input sid perm bg_tasks stem marker claimed msid created reason=""
  input=""; [ -t 0 ] || input="$(cat)"
  sid="$(jq -r '.session_id // empty' <<< "$input" 2>/dev/null)"
  perm="$(jq -r '.permission_mode // empty' <<< "$input" 2>/dev/null)"
  bg_tasks="$(jq -r '(.background_tasks // []) | length' <<< "$input" 2>/dev/null)"

  _wb_session_lookup "$sid" || exit 0
  stem="$(wb_task_stem "$WB_LOOKUP_FILE")"
  marker="$(wb_clear_marker "$stem")"
  [ -f "$marker" ] || exit 0
  msid="$(_ac_field "$marker" sid)"
  [ -z "$msid" ] || [ "$msid" = "${sid:-$WB_LOOKUP_SID}" ] || exit 0   # another session of the task asked
  claimed="$marker.claimed"
  mv "$marker" "$claimed" 2>/dev/null || exit 0

  created="$(_ac_field "$claimed" created)"
  if [ $(( $(date +%s) - ${created:-0} )) -gt "$WB_CLEAR_MAX_AGE" ]; then
    reason="the request was over $WB_CLEAR_MAX_AGE seconds old"
  elif [ "${bg_tasks:-0}" -gt 0 ] 2>/dev/null; then
    reason="background tasks are still running in this session"
  elif wb_decide_buffer_open "$stem"; then
    reason="a /decide buffer is open, and a restart would lose its answers"
  fi
  [ -z "$reason" ] || _ac_give_up "$stem" "$claimed" "$WB_LOOKUP_PANE" "$reason"

  printf 'mode=%s\nlookup_pane=%s\nlookup_sid=%s\n' "$perm" "$WB_LOOKUP_PANE" "$WB_LOOKUP_SID" >> "$claimed"
  if [ -n "$WB_LOOKUP_PANE" ]; then
    # Owned by the tmux server, so it outlives the pane it respawns.
    tmux run-shell -b "$(printf '%q ' "$AC_SELF" helper "$claimed" "$perm" "$(command -v claude)")" 2>/dev/null \
      || _ac_give_up "$stem" "$claimed" "$WB_LOOKUP_PANE" "tmux couldn't start the helper"
  else
    wb_detach "$AC_SELF" helper "$claimed" "$perm" "$(command -v claude)"
  fi
  exit 0
}

helper() {
  local claimed="$1" perm="$2" bin="$3" stem file pane sid created i working idx status wt job name att
  stem="$(basename "$claimed" .claimed)"
  file="$(wb_task_file_for_stem "$stem")"
  pane="$(_ac_field "$claimed" lookup_pane)"; sid="$(_ac_field "$claimed" lookup_sid)"
  created="$(_ac_field "$claimed" created)"
  wb_task_exists "$file" || _ac_give_up "$stem" "$claimed" "$pane" "the task file is gone"
  [ -n "$bin" ] || _ac_give_up "$stem" "$claimed" "$pane" "claude isn't on the PATH"

  # Settle: the notify hook's `done` runs alongside this one and the registry
  # turns idle just after Stop; a prompt Jet sends now makes it busy again.
  for i in $(seq 20); do
    working=""
    [ -z "$pane" ] || working="$(tmux show -pv -t "$pane" @claude_working 2>/dev/null)"
    _wb_registry_reload; idx="${WB_REG_BY_SID[$sid]:-}"
    status=""; [ -z "$idx" ] || status="$(wb_registry_field "$idx" 4)"
    [ -z "$working" ] && [ "$status" != busy ] && break
    sleep 0.25
  done
  [ -z "$working" ] && [ "$status" != busy ] || _ac_give_up "$stem" "$claimed" "$pane" "a new turn started"
  case "$status" in ''|idle) ;; *) _ac_give_up "$stem" "$claimed" "$pane" "Claude is $status, not idle" ;; esac
  [ $(( $(date +%s) - ${created:-0} )) -le "$WB_CLEAR_MAX_AGE" ] \
    || _ac_give_up "$stem" "$claimed" "$pane" "the request was over $WB_CLEAR_MAX_AGE seconds old"

  wt="$(wb_task_worktree_abs "$file" 2>/dev/null)"
  if [ -n "$pane" ]; then
    [ -n "$wt" ] && [ -d "$wt" ] || wt="$(tmux display -p -t "$pane" '#{pane_current_path}' 2>/dev/null)"
    _ac_input_pending "$pane" && _ac_give_up "$stem" "$claimed" "$pane" "$AC_PENDING"
    tmux display-message -d 1500 -t "$pane" "wb: clearing for the /handoff pick-up…" 2>/dev/null
    sleep 1.5
    _ac_input_pending "$pane" && _ac_give_up "$stem" "$claimed" "$pane" "$AC_PENDING"
    [ -z "$(tmux show -pv -t "$pane" @claude_working 2>/dev/null)" ] \
      || _ac_give_up "$stem" "$claimed" "$pane" "a new turn started"
    tmux respawn-pane -k -t "$pane" -c "$wt" "$(wb_claude_pane_cmd "$bin" "$perm" "$WB_CLEAR_PROMPT")" \
      || _ac_give_up "$stem" "$claimed" "$pane" "tmux couldn't respawn the pane"
    rm -f "$claimed"
    wb_handoff_log "$stem" "restarted the pane $pane in a clean context"
    _ac_record_primary "$file" "$pane" "$sid"
  else
    [ -n "$idx" ] || _ac_give_up "$stem" "$claimed" "" "the background session is gone"
    job="$(wb_registry_field "$idx" 7)"; name="$(wb_registry_field "$idx" 6)"
    [ -n "$wt" ] && [ -d "$wt" ] || wt="$(wb_registry_field "$idx" 5)"
    # Stopping the job would drop what Jet is typing in an attached client.
    att="$(_wb_bg_attached_pane "$job")" \
      && _ac_give_up "$stem" "$claimed" "$att" "you're attached to the background session $job"
    wb_watchdog 10 "$bin" stop "$job" >/dev/null 2>&1 </dev/null \
      || _ac_give_up "$stem" "$claimed" "" "the background session $job wouldn't stop"
    if _wb_start_bg "$name" "$wt" "$file" "$WB_CLEAR_PROMPT" "$perm" >/dev/null 2>&1; then
      rm -f "$claimed"
      wb_handoff_log "$stem" "restarted the background session $name in a clean context"
    else
      _ac_give_up "$stem" "$claimed" "" "the background session stopped but didn't start again; run wb resume"
    fi
  fi
  exit 0
}

# _ac_record_primary <file> <pane> <old_sid> — once the new Claude registers
# in the pane, make it the record's @primary, as a respawn by hand would.
_ac_record_primary() {
  local i idx new
  for i in $(seq 40); do
    _wb_registry_reload
    idx="${WB_REG_BY_PANE[$2]:-}"
    if [ -n "$idx" ]; then
      new="$(wb_registry_field "$idx" 1)"
      [ "$new" != "$3" ] && break
    fi
    new=""; sleep 0.25
  done
  [ -n "$new" ] || return 0
  wb_lock_acquire "$1" || return 0
  wb_task_set_primary "$1" "$new"
  wb_lock_release "$1"
}

case "$1" in
  stop) stop_hook ;;
  helper) shift; helper "$@" ;;
esac
exit 0
