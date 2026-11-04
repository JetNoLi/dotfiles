# decide.sh — the open /decide surfaces of a task (KTD7, KTD8). Each task
# with questions waiting on Jet has $WB_STATE_DIR/needs-you/<stem>, one line
# per open surface: "buffer <answer file> <nvim pane>" or "page <url>". The
# picker shows the task as needing him while the file exists; the Stop
# hook's `done` never touches it. /decide removes a surface once all its
# items are answered and recorded, and the file goes with the last one;
# closing the task's session (wb down, wb done) removes it too. Writers
# hold the task's lock, so two surfaces opening or closing at once can't
# drop each other's lines. Outside a task, a surface belongs to the tmux
# session /decide runs in: the picker reads needs-you by session name.

# wb_needs_you_file <stem>
wb_needs_you_file() { printf '%s/needs-you/%s\n' "$WB_STATE_DIR" "$1"; }

# wb_decide_surfaces <stem> — the task's open surfaces, one per line.
wb_decide_surfaces() { cat "$(wb_needs_you_file "$1")" 2>/dev/null; return 0; }

# wb_decide_open <stem> <buffer|page> <ref> [pane] — record an open surface.
# A buffer's line carries its nvim pane and replaces an earlier line for the
# same file.
wb_decide_open() {
  local f; f="$(wb_needs_you_file "$1")"
  mkdir -p "${f%/*}"
  [ "$2" != buffer ] || _wb_decide_drop "$f" "$3"
  grep -qxF -- "$2 $3${4:+ $4}" "$f" 2>/dev/null || printf '%s %s%s\n' "$2" "$3" "${4:+ $4}" >> "$f"
}

# _wb_decide_drop <needs_you_file> <file|url> — remove that surface's line.
_wb_decide_drop() {
  [ -f "$1" ] || return 0
  awk -v ref="$2" '
    { r = $0; t = r; sub(/ .*/, "", t); sub(/^[^ ]* /, "", r); if (t == "buffer") sub(/ [^ ]*$/, "", r) }
    r != ref' "$1" > "$1.tmp.$$" && mv "$1.tmp.$$" "$1"
}

# wb_decide_buffer_open <stem> — a buffer surface whose nvim pane is still
# open. A closed pane's line can stay while its items wait on an answer;
# those are read from the answer file, and a restart can't lose them.
wb_decide_buffer_open() {
  local kind rest
  while read -r kind rest; do
    [ "$kind" = buffer ] && _wb_pane_exists "${rest##* }" && return 0
  done < <(wb_decide_surfaces "$1")
  return 1
}

# _wb_pane_exists <pane_id> — tmux 3.5 prints nothing and exits 0 for a
# pane that is gone, so the printed id is compared.
_wb_pane_exists() { [ "$(tmux display -p -t "$1" '#{pane_id}' 2>/dev/null)" = "$1" ]; }

# _wb_decide_target <verb> [--task …] [args…] — whose surface this is. In a
# task, WB_DECIDE_KEY is its stem and writers lock its file. Outside one, in
# tmux, the key is the session's name and writers lock its needs-you file;
# WB_TASK is empty. A --task that names no task still fails.
_wb_decide_target() {
  local a s given=0
  WB_DECIDE_KEY=""; WB_DECIDE_LOCK=""; WB_TASK=""
  for a in "$@"; do [ "$a" != --task ] || given=1; done
  if [ "$given" = 1 ]; then
    _wb_entry_task "$@" || return 1
  else
    _wb_entry_task "$@" 2>/dev/null || WB_TASK=""
  fi
  if [ -n "$WB_TASK" ]; then
    WB_DECIDE_KEY="$(wb_task_stem "$WB_TASK")"; WB_DECIDE_LOCK="$WB_TASK"
  elif [ -n "${TMUX_PANE:-}" ] && s="$(tmux display -p -t "$TMUX_PANE" '#S' 2>/dev/null)" && [ -n "$s" ]; then
    WB_TASK=""; WB_DECIDE_KEY="$s"; WB_DECIDE_LOCK="$(wb_needs_you_file "$s")"; WB_LOOKUP_PANE="$TMUX_PANE"
  else
    echo "wb $1: this session is neither a wb task nor in tmux, so nothing can mark it as needing Jet" >&2
    return 1
  fi
}

# cmd_decide_path [--task …] — a fresh answer-file path for this task's (or,
# outside one, this tmux session's) buffer, its directory created.
cmd_decide_path() {
  local dir
  _wb_decide_target decide-path "$@" || return 1
  dir="$WB_STATE_DIR/decide/$WB_DECIDE_KEY"
  mkdir -p "$dir"
  printf '%s/%s.md\n' "$dir" "$(date +%Y%m%d-%H%M%S)"
}

# cmd_decide_open <buffer|page> <ref> [--task …] — mark a surface as open
# (the page branch; decide-buffer does this itself).
cmd_decide_open() {
  _wb_decide_target decide-open "$@" || return 1
  case "${WB_ARGS[0]:-}" in buffer|page) ;; *) echo "usage: wb decide-open <buffer|page> <file|url>" >&2; return 1 ;; esac
  [ -n "${WB_ARGS[1]:-}" ] || { echo "usage: wb decide-open <buffer|page> <file|url>" >&2; return 1; }
  wb_lock_acquire "$WB_DECIDE_LOCK" || return 75
  wb_decide_open "$WB_DECIDE_KEY" "${WB_ARGS[0]}" "${WB_ARGS[1]}"
  wb_lock_release "$WB_DECIDE_LOCK"
}

# cmd_decide_buffer <answer_file> [--task …] — open the file in nvim in a
# split of the task's tmux session, wait for that pane to close, and print
# the file's path. /decide runs it as a background command, so Jet can
# take as long as he likes and the session is re-invoked when it exits.
cmd_decide_buffer() {
  local file target pane key editor session
  _wb_decide_target decide-buffer "$@" || return 1
  file="${WB_ARGS[0]:-}"
  [ -n "$file" ] && [ -f "$file" ] || { echo "usage: wb decide-buffer <answer file> (the file must exist)" >&2; return 1; }
  key="$WB_DECIDE_KEY"
  if [ -n "${WB_LOOKUP_PANE:-}" ] && _wb_pane_exists "$WB_LOOKUP_PANE"; then
    target="$WB_LOOKUP_PANE"
  elif [ -n "$WB_TASK" ] && session="$(wb_task_session "$WB_TASK")"; then
    target="=$session:"
  else
    echo "wb decide-buffer: $key has no tmux session to open the buffer in" >&2; return 1
  fi
  editor="$(command -v nvim)" || { echo "wb decide-buffer: nvim isn't on the PATH" >&2; return 1; }
  # Locked across the split, so the surface is marked as soon as it exists.
  wb_lock_acquire "$WB_DECIDE_LOCK" || return 75
  pane="$(tmux split-window -h -t "$target" -c "${file%/*}" -P -F '#{pane_id}' "$(printf '%q ' "$editor" "$file")")" \
    || { wb_lock_release "$WB_DECIDE_LOCK"; echo "wb decide-buffer: tmux couldn't open the split" >&2; return 1; }
  wb_decide_open "$key" buffer "$file" "$pane"
  wb_lock_release "$WB_DECIDE_LOCK"
  while _wb_pane_exists "$pane"; do sleep 1; done
  echo "$file"
}

# cmd_decide_clear <file|url> | --all [--task …] — the surface is answered
# and recorded; drop it, and the needs-you file once none is left.
cmd_decide_clear() {
  local f ref
  _wb_decide_target decide-clear "$@" || return 1
  ref="${WB_ARGS[0]:-}"
  [ -n "$ref" ] || { echo "usage: wb decide-clear <file|url> | --all" >&2; return 1; }
  f="$(wb_needs_you_file "$WB_DECIDE_KEY")"
  [ -f "$f" ] || return 0
  wb_lock_acquire "$WB_DECIDE_LOCK" || return 75
  [ "$ref" = --all ] || _wb_decide_drop "$f" "$ref"
  [ "$ref" != --all ] && [ -s "$f" ] || rm -f "$f"
  wb_lock_release "$WB_DECIDE_LOCK"
}

# cmd_decide_spec_check <spec.json> — check a /decide page spec before it is
# published, printing each problem. The fields are described in the decide
# skill's references/page-spec.md.
cmd_decide_spec_check() {
  local problems
  [ -f "${1:-}" ] || { echo "usage: wb decide-spec-check <spec.json>" >&2; return 1; }
  jq empty "$1" 2>/dev/null || { echo "wb decide-spec-check: $1 isn't valid JSON" >&2; return 1; }
  problems="$(jq -r '
    def str: type == "string" and length > 0;
    [ (if (.title | str) then empty else "title is missing" end),
      (if .layout == "items" or .layout == "verdicts" then empty else "layout must be \"items\" or \"verdicts\"" end),
      (if (.items | type) == "array" and (.items | length) > 0 then empty else "items must be a non-empty list" end),
      ((.items // [])[] | select((.id | str) | not) | "an item has no id: \(.title // "untitled")"),
      ((.items // [])[] | select((.title | str) | not) | "item \(.id // "?") has no title"),
      ([(.items // [])[].id | select(str)] | group_by(.)[] | select(length > 1) | "item id \(.[0]) is used twice"),
      (if .layout == "items" then
         (.items // [])[] | select(((.options | type) == "array" and (.options | length) >= 2 and all(.options[]; .id | str)) | not)
         | "item \(.id // "?") needs at least two options, each with an id"
       else empty end),
      (if .layout == "verdicts" then
         (if (.verdicts | type) == "array" and (.verdicts | length) >= 2 and all(.verdicts[]; (.id | str) and (.label | str)) then empty
          else "verdicts must list at least two, each with an id and label" end),
         ([(.verdicts // [])[].id] as $v | (.items // [])[] | select(.suggested as $s | $s != null and ($v | index($s)) == null)
          | "item \(.id // "?") suggests \(.suggested), which is not one of the verdicts")
       else empty end)
    ] | .[]' "$1" 2>&1)" || { echo "wb decide-spec-check: $1 has the wrong shape: $problems" >&2; return 1; }
  [ -z "$problems" ] || { printf 'wb decide-spec-check: %s\n' "$problems" >&2; return 1; }
  echo "ok"
}
