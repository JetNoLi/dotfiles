# handoff.sh — the verbs the /handoff and /decide skills write through
# (KTD1, KTD14). Each one takes the task lock, writes and releases it in this
# one process: the lock is keyed on $BASHPID, so a skill's separate shell
# calls could never hold it across a write.

# wb_task_for_session [session_id] — the task file a Claude session works on.
# The session is found in the registry by id, else as an ancestor of this
# process (a skill's shell runs under its Claude). A registry entry with a
# pane goes through the pane's tmux session; one without (a background
# session) maps its name, which wb new sets to the task stem. With no
# registry entry, $TMUX_PANE is tried. Fails when nothing maps to a task.
wb_task_for_session() {
  local sid="${1:-}" idx="" pid pane="" file
  _wb_registry_load
  if [ -n "$sid" ]; then
    idx="${WB_REG_BY_SID[$sid]:-}"
  else
    pid="$PPID"
    while [ -n "$pid" ] && [ "$pid" -gt 1 ] 2>/dev/null; do
      idx="${WB_REG_BY_PID[$pid]:-}"
      [ -z "$idx" ] || break
      pid="${WB_PS_PARENT[$pid]:-}"
    done
  fi
  if [ -n "$idx" ]; then
    pane="$(wb_registry_field "$idx" 3)"
    if [ -z "$pane" ]; then
      file="$(wb_task_file_for_stem "$(wb_registry_field "$idx" 6)")"
      wb_task_exists "$file" || return 1
      echo "$file"; return 0
    fi
  fi
  pane="${pane:-${TMUX_PANE:-}}"
  [ -n "$pane" ] || return 1
  file="$(wb_session_task_file "$(tmux display -p -t "$pane" '#S' 2>/dev/null)")" || return 1
  wb_task_exists "$file" || return 1
  echo "$file"
}

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
    WB_TASK="$(wb_task_for_session "$sid")" \
      || { echo "wb $verb: this session isn't a wb task, so there is no task to write to" >&2; return 1; }
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

# cmd_handoff_to <target_stem> [--task …] [--session-id …] — stdin becomes a
# `from <stem>` entry in the target's Handoffs (R7). The sender is the
# calling session's task; outside one the entry says so.
cmd_handoff_to() {
  local from target
  _wb_entry_task handoff-to "$@" 2>/dev/null || true
  from="${WB_TASK:+$(wb_task_stem "$WB_TASK")}"
  [ "${#WB_ARGS[@]}" -eq 1 ] || { echo "usage: wb handoff-to <repo>--<slug> < body" >&2; return 1; }
  target="$(wb_task_file_for_stem "${WB_ARGS[0]}")"
  wb_task_exists "$target" || { echo "wb handoff-to: no task '${WB_ARGS[0]}'" >&2; return 1; }
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

# cmd_pickup [--task …] [--session-id …] — the latest checkpoint and the
# entries since it. Fails silently when there is no checkpoint.
cmd_pickup() {
  _wb_entry_task pickup "$@" || return 1
  wb_task_pickup "$WB_TASK"
}

# wb_pickup_marker <stem> — the file that tells the next startup of the
# task's Claude to pick up its checkpoint. It holds "wait" or "start".
wb_pickup_marker() { printf '%s/pickup/%s\n' "$WB_STATE_DIR" "$1"; }
