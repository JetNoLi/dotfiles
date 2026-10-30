# decide.sh — the open /decide surfaces of a task (KTD7, KTD8). Each task
# with questions waiting on Jet has $WB_STATE_DIR/needs-you/<stem>, one line
# per open surface: "buffer <answer file>" or "page <url>". The picker shows
# the task as needing him while the file exists; the Stop hook's `done`
# never touches it. /decide removes a surface once all its items are
# answered and recorded, and the file goes with the last one.

# wb_needs_you_file <stem>
wb_needs_you_file() { printf '%s/needs-you/%s\n' "$WB_STATE_DIR" "$1"; }

# wb_decide_surfaces <stem> — the task's open surfaces, one per line.
wb_decide_surfaces() { cat "$(wb_needs_you_file "$1")" 2>/dev/null; return 0; }

# wb_decide_open <stem> <buffer|page> <ref> — record an open surface.
wb_decide_open() {
  local f; f="$(wb_needs_you_file "$1")"
  mkdir -p "${f%/*}"
  grep -qxF -- "$2 $3" "$f" 2>/dev/null || printf '%s %s\n' "$2" "$3" >> "$f"
}

# _wb_pane_exists <pane_id> — tmux 3.5 prints nothing and exits 0 for a
# pane that is gone, so the printed id is compared.
_wb_pane_exists() { [ "$(tmux display -p -t "$1" '#{pane_id}' 2>/dev/null)" = "$1" ]; }

# cmd_decide_path [--task …] — a fresh answer-file path for this task's
# buffer, its directory created.
cmd_decide_path() {
  local dir
  _wb_entry_task decide-path "$@" || return 1
  dir="$WB_STATE_DIR/decide/$(wb_task_stem "$WB_TASK")"
  mkdir -p "$dir"
  printf '%s/%s.md\n' "$dir" "$(date +%Y%m%d-%H%M%S)"
}

# cmd_decide_open <buffer|page> <ref> [--task …] — mark a surface as open
# (the page branch; decide-buffer does this itself).
cmd_decide_open() {
  _wb_entry_task decide-open "$@" || return 1
  case "${WB_ARGS[0]:-}" in buffer|page) ;; *) echo "usage: wb decide-open <buffer|page> <file|url>" >&2; return 1 ;; esac
  [ -n "${WB_ARGS[1]:-}" ] || { echo "usage: wb decide-open <buffer|page> <file|url>" >&2; return 1; }
  wb_decide_open "$(wb_task_stem "$WB_TASK")" "${WB_ARGS[0]}" "${WB_ARGS[1]}"
}

# cmd_decide_buffer <answer_file> [--task …] — open the file in nvim in a
# split of the task's tmux session, wait for that pane to close, and print
# the file's path. /decide runs it as a background command, so Jet can
# take as long as he likes and the session is re-invoked when it exits.
cmd_decide_buffer() {
  local file target pane stem editor
  _wb_entry_task decide-buffer "$@" || return 1
  file="${WB_ARGS[0]:-}"
  [ -n "$file" ] && [ -f "$file" ] || { echo "usage: wb decide-buffer <answer file> (the file must exist)" >&2; return 1; }
  stem="$(wb_task_stem "$WB_TASK")"
  if [ -n "${WB_LOOKUP_PANE:-}" ] && _wb_pane_exists "$WB_LOOKUP_PANE"; then
    target="$WB_LOOKUP_PANE"
  elif tmux has-session -t "=$stem" 2>/dev/null; then
    target="=$stem:"
  else
    echo "wb decide-buffer: $stem has no tmux session to open the buffer in" >&2; return 1
  fi
  editor="$(command -v nvim)" || { echo "wb decide-buffer: nvim isn't on the PATH" >&2; return 1; }
  wb_decide_open "$stem" buffer "$file"
  pane="$(tmux split-window -h -t "$target" -c "${file%/*}" -P -F '#{pane_id}' "$(printf '%q ' "$editor" "$file")")" \
    || { echo "wb decide-buffer: tmux couldn't open the split" >&2; return 1; }
  while _wb_pane_exists "$pane"; do sleep 1; done
  echo "$file"
}

# cmd_decide_clear <file|url> | --all [--task …] — the surface is answered
# and recorded; drop it, and the needs-you file once none is left.
cmd_decide_clear() {
  local f ref
  _wb_entry_task decide-clear "$@" || return 1
  ref="${WB_ARGS[0]:-}"
  [ -n "$ref" ] || { echo "usage: wb decide-clear <file|url> | --all" >&2; return 1; }
  f="$(wb_needs_you_file "$(wb_task_stem "$WB_TASK")")"
  [ -f "$f" ] || return 0
  if [ "$ref" != --all ]; then
    awk -v ref="$ref" '{ r = $0; sub(/^[^ ]* /, "", r) } r != ref' "$f" > "$f.tmp.$$" && mv "$f.tmp.$$" "$f"
  fi
  [ "$ref" != --all ] && [ -s "$f" ] || rm -f "$f"
}
