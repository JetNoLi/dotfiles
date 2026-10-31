# handoff.sh — the verbs the /handoff and /decide skills write through
# (KTD1, KTD14). Each one takes the task lock, writes and releases it in this
# one process: the lock is keyed on $BASHPID, so a skill's separate shell
# calls could never hold it across a write.

# _wb_session_lookup [session_id] — find the Claude session and its task.
# The session is looked up in the registry by the given id, then by
# $CLAUDE_PID, which Claude Code sets for the commands it runs. An entry with
# a pane goes through that pane's tmux session; one without (a background
# session) maps its name, which wb new sets to the task stem. With no
# registry entry, or a pane-less one whose name is no task, $TMUX_PANE is
# tried. Sets WB_LOOKUP_FILE, WB_LOOKUP_SID and WB_LOOKUP_PANE; fails when
# nothing maps to a task.
_wb_session_lookup() {
  local sid="${1:-}" idx="" file
  WB_LOOKUP_FILE=""; WB_LOOKUP_SID="$sid"; WB_LOOKUP_PANE=""
  _wb_registry_load
  [ -z "$sid" ] || idx="${WB_REG_BY_SID[$sid]:-}"
  [ -n "$idx" ] || [ -z "${CLAUDE_PID:-}" ] || idx="${WB_REG_BY_PID[$CLAUDE_PID]:-}"
  if [ -n "$idx" ]; then
    WB_LOOKUP_SID="$(wb_registry_field "$idx" 1)"
    WB_LOOKUP_PANE="$(wb_registry_field "$idx" 3)"
    if [ -z "$WB_LOOKUP_PANE" ]; then
      file="$(wb_task_file_for_stem "$(wb_registry_field "$idx" 6)")"
      if wb_task_exists "$file"; then WB_LOOKUP_FILE="$file"; return 0; fi
    fi
  fi
  WB_LOOKUP_PANE="${WB_LOOKUP_PANE:-${TMUX_PANE:-}}"
  [ -n "$WB_LOOKUP_PANE" ] || return 1
  file="$(wb_session_task_file "$(tmux display -p -t "$WB_LOOKUP_PANE" '#S' 2>/dev/null)")" || return 1
  wb_task_exists "$file" || return 1
  WB_LOOKUP_FILE="$file"
}

# wb_task_for_session [session_id] — print the session's task file.
wb_task_for_session() { _wb_session_lookup "${1:-}" && echo "$WB_LOOKUP_FILE"; }

# _wb_entry_task <verb> [--task <stem|file>] [--session-id <id>] — set
# WB_TASK from the flags, else from the calling session. Leftover arguments
# go to WB_ARGS.
_wb_entry_task() {
  local verb="$1" task="" sid=""
  shift
  WB_TASK=""; WB_ARGS=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --task|--session-id)
        [ -n "${2-}" ] || { echo "wb $verb: $1 requires a value" >&2; return 1; }
        if [ "$1" = --task ]; then task="$2"; else sid="$2"; fi
        shift 2 ;;
      *) WB_ARGS+=("$1"); shift ;;
    esac
  done
  if [ -n "$task" ]; then
    WB_TASK="$task"
    wb_task_exists "$WB_TASK" || WB_TASK="$(wb_task_file_for_stem "$task")"
    wb_task_exists "$WB_TASK" || { echo "wb $verb: no task '$task'" >&2; return 1; }
  else
    _wb_session_lookup "$sid" \
      || { echo "wb $verb: this session isn't a wb task, so there is no task to write to" >&2; return 1; }
    WB_TASK="$WB_LOOKUP_FILE"
  fi
}

# _wb_read_body <verb> — stdin into WB_BODY; an empty body is refused.
_wb_read_body() {
  WB_BODY="$(cat)"
  [ -n "${WB_BODY//[[:space:]]/}" ] || { echo "wb $1: nothing on stdin to write" >&2; return 1; }
}

# cmd_task_for_session [--session-id <id>] — print the session's task file.
cmd_task_for_session() {
  _wb_entry_task task-for-session "$@" || return 1
  echo "$WB_TASK"
}

# cmd_checkpoint [--task …] [--session-id …] — stdin becomes a
# `checkpoint` entry in the task's Handoffs (R1).
cmd_checkpoint() {
  _wb_entry_task checkpoint "$@" || return 1
  _wb_read_body checkpoint || return 1
  wb_lock_acquire "$WB_TASK" || return 75
  wb_task_append_entry "$WB_TASK" checkpoint "$WB_BODY"
  wb_lock_release "$WB_TASK"
  echo "$WB_TASK"
}

# cmd_handoff_to <target> [--task …] [--session-id …] — stdin becomes a
# `from <stem>` entry in the target's Handoffs (R7). The target is a stem, or
# a query matching one task. Prints the target's file. The sender is the
# calling session's task; outside one the entry says so.
cmd_handoff_to() {
  local from target
  _wb_entry_task handoff-to "$@" 2>/dev/null || true
  from="${WB_TASK:+$(wb_task_stem "$WB_TASK")}"
  [ "${#WB_ARGS[@]}" -eq 1 ] || { echo "usage: wb handoff-to <repo>--<slug> < body" >&2; return 1; }
  target="$(wb_task_file_for_stem "${WB_ARGS[0]}")"
  wb_task_exists "$target" || target="$(_wb_find_task "${WB_ARGS[0]}" "wb handoff-to")" || return 1
  _wb_read_body handoff-to || return 1
  wb_lock_acquire "$target" || return 75
  wb_task_append_entry "$target" "from ${from:-a session outside wb}" "$WB_BODY"
  wb_lock_release "$target"
  echo "$target"
}

# cmd_decision <title> [--task …] [--session-id …] — stdin becomes the
# Decisions entry with that title, replacing an earlier one (R18).
cmd_decision() {
  _wb_entry_task decision "$@" || return 1
  [ "${#WB_ARGS[@]}" -eq 1 ] && [ -n "${WB_ARGS[0]}" ] \
    || { echo "usage: wb decision <title> < body" >&2; return 1; }
  _wb_read_body decision || return 1
  wb_lock_acquire "$WB_TASK" || return 75
  wb_task_set_decision "$WB_TASK" "${WB_ARGS[0]}" "$WB_BODY"
  wb_lock_release "$WB_TASK"
}

# wb_pickup_text <file> — the latest checkpoint, the entries since it, and
# the task's open /decide surfaces. Fails, printing nothing, without a
# checkpoint.
wb_pickup_text() {
  local surfaces
  wb_task_pickup "$1" || return 1
  surfaces="$(wb_decide_surfaces "$(wb_task_stem "$1")")"
  [ -z "$surfaces" ] || printf '\n== Open /decide surfaces waiting on Jet ==\n%s\n' "$surfaces"
}

# cmd_pickup [--task …] [--session-id …] — wb_pickup_text for the task.
cmd_pickup() {
  _wb_entry_task pickup "$@" || return 1
  wb_pickup_text "$WB_TASK"
}

# wb_pickup_marker <stem> — the file that tells the next startup of the
# task's Claude to pick up its checkpoint. It holds "wait" or "start".
wb_pickup_marker() { printf '%s/pickup/%s\n' "$WB_STATE_DIR" "$1"; }

# wb_pickup_mark <stem> <wait|start> — write that marker.
wb_pickup_mark() {
  local f; f="$(wb_pickup_marker "$1")"
  mkdir -p "${f%/*}" && echo "$2" > "$f"
}

# --- auto-clear (KTD3) ---------------------------------------------------------------
# /handoff asks for a clean context with `wb clear-request`. The Stop hook
# (claude-autoclear.sh) claims the request once the turn ends and restarts
# Claude; a prompt submitted first cancels it.

WB_CLEAR_MAX_AGE="${WB_CLEAR_MAX_AGE:-120}"   # seconds a clear request stays good

# wb_clear_marker <stem>
wb_clear_marker() { printf '%s/clear/%s\n' "$WB_STATE_DIR" "$1"; }

# wb_handoff_log <stem> <message> — one line in $WB_STATE_DIR/handoff.log.
wb_handoff_log() {
  mkdir -p "$WB_STATE_DIR"
  printf '%s %s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" >> "$WB_STATE_DIR/handoff.log"
}

# cmd_clear_request [--task …] [--session-id …] — arm the auto-clear for this
# session's task, and the pick-up marker its restart will consume.
cmd_clear_request() {
  local marker
  _wb_entry_task clear-request "$@" || return 1
  marker="$(wb_clear_marker "$(wb_task_stem "$WB_TASK")")"
  mkdir -p "${marker%/*}"
  printf 'sid=%s\npane=%s\ncreated=%s\n' "${WB_LOOKUP_SID:-}" "${WB_LOOKUP_PANE:-}" "$(date +%s)" > "$marker.tmp.$$"
  mv "$marker.tmp.$$" "$marker"
  wb_pickup_mark "$(wb_task_stem "$WB_TASK")" wait
  echo "wb: this session restarts in a clean context once the turn ends"
}

# cmd_clear_cancel [--session-id …] — drop an unclaimed request; Jet sent a
# prompt, so the turn that asked for it is over.
cmd_clear_cancel() {
  local stem
  _wb_entry_task clear-cancel "$@" 2>/dev/null || return 0
  stem="$(wb_task_stem "$WB_TASK")"
  [ -f "$(wb_clear_marker "$stem")" ] || return 0
  rm -f "$(wb_clear_marker "$stem")" "$(wb_pickup_marker "$stem")"
  wb_handoff_log "$stem" "cancelled: a prompt was sent before the turn ended"
}
