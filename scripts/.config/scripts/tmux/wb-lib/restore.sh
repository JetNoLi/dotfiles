# restore.sh — save every tmux session, with the Claude conversation in each
# pane, and rebuild them after a restart. `wb save` writes a snapshot;
# `wb restore` recreates the sessions it lists, typing `claude --resume <id>`
# into each Claude pane. Once a restore (or a manual save) arms it, the
# status bar runs `wb save --auto` so a snapshot is never far behind.
#
# A snapshot is TSV, one line per session then one per pane:
#   S  session  @task  @wb_repo  @wb_slug  @wb_branch
#   P  session  win_index  win_name  win_layout  win_active  win_w  win_h
#      pane_index  pane_active  cwd  kind  session_id  claude_cwd  perm  extra
# kind is claude, attach (a pane on a background session), nvim or shell;
# extra is the attach job id or nvim's arguments.

WB_SAVE_DIR="${WB_SAVE_DIR:-$WB_STATE_DIR/sessions}"
WB_SAVE_EVERY="${WB_SAVE_EVERY:-300}"   # seconds between automatic saves
WB_SAVE_KEEP="${WB_SAVE_KEEP:-50}"      # snapshots kept

# _wb_pane_nvim_args <pane_pid> — set REPLY to the arguments of nvim running
# in a pane (the pane's own process or a child), or fail.
_wb_pane_nvim_args() {
  local pid cmd bin
  for pid in "$1" ${WB_PS_KIDS[$1]:-}; do
    cmd="${WB_PS_CMD[$pid]:-}"
    bin="${cmd%% *}"
    [ "${bin##*/}" = nvim ] || continue
    REPLY=""; [[ "$cmd" == *" "* ]] && REPLY="${cmd#* }"
    return 0
  done
  return 1
}

# _wb_save_lines — the snapshot of the running tmux server, on stdout.
_wb_save_lines() {
  _wb_registry_load
  local sess task repo slug branch win wname layout wactive ww wh pidx pactive pane ppid cwd
  local kind sid ccwd perm extra idx cmd
  local -a rec
  while IFS=$'\t' read -r sess task repo slug branch; do
    printf 'S\t%s\t%s\t%s\t%s\t%s\n' "$sess" "$task" "$repo" "$slug" "$branch"
  done < <(tmux list-sessions -F $'#{session_name}\t#{@task}\t#{@wb_repo}\t#{@wb_slug}\t#{@wb_branch}' 2>/dev/null)

  while IFS=$'\t' read -r sess win wname layout wactive ww wh pidx pactive pane ppid cwd; do
    kind=shell sid="" ccwd="" perm="" extra=""
    if _wb_pane_claude_pid "$ppid"; then
      cmd="${WB_PS_CMD[$REPLY]}"
      idx="${WB_REG_BY_PANE[$pane]:-}"
      if [ -z "$idx" ] && [[ "$cmd" =~ ^[^\ ]*claude\ attach\ ([^\ ]+) ]]; then
        extra="${BASH_REMATCH[1]}"
        idx="${WB_REG_BY_JOB[$extra]:-}"
      fi
      if [ -n "$idx" ]; then
        wb_tsv_split "${WB_REG_ROWS[$idx]}" rec
        sid="${rec[1]}" ccwd="${rec[5]}"
        if [ -n "$extra" ]; then kind=attach; else kind=claude; fi
        [[ "$cmd" =~ --permission-mode[=\ ]([^\ ]+) ]] && perm="${BASH_REMATCH[1]}"
      else
        extra=""   # a Claude the registry can't place has no id to resume
      fi
    elif _wb_pane_nvim_args "$ppid"; then
      kind=nvim extra="$REPLY"
    fi
    printf 'P\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$sess" "$win" "$wname" "$layout" "$wactive" "$ww" "$wh" "$pidx" "$pactive" \
      "$cwd" "$kind" "$sid" "$ccwd" "$perm" "$extra"
  done < <(tmux list-panes -a -F $'#{session_name}\t#{window_index}\t#{window_name}\t#{window_layout}\t#{window_active}\t#{window_width}\t#{window_height}\t#{pane_index}\t#{pane_active}\t#{pane_id}\t#{pane_pid}\t#{pane_current_path}' 2>/dev/null)
}

# cmd_save [--auto] — write a snapshot of every session. --auto (the status
# bar) does nothing until the newest one is WB_SAVE_EVERY seconds old, and
# only adds a file when something changed.
cmd_save() {
  local auto=0 latest tmp now stamp
  [ "${1:-}" = --auto ] && auto=1
  mkdir -p "$WB_SAVE_DIR"
  latest="$WB_SAVE_DIR/latest.tsv"
  now="$(date +%s)"
  if [ "$auto" = 1 ] && [ -f "$latest" ] && [ $(( now - $(wb_mtime "$latest") )) -lt "$WB_SAVE_EVERY" ]; then
    return 0
  fi
  tmp="$(mktemp "$WB_SAVE_DIR/.save.XXXXXX")"
  _wb_save_lines > "$tmp"
  if ! grep -q '^P' "$tmp"; then
    rm -f "$tmp"
    [ "$auto" = 1 ] || echo "wb save: no tmux panes to save" >&2
    return 1
  fi
  if [ -f "$latest" ] && cmp -s "$tmp" "$latest"; then
    rm -f "$tmp"; touch "$latest"
  else
    stamp="$(date +%Y%m%d-%H%M%S)"
    cp "$tmp" "$WB_SAVE_DIR/$stamp.tsv"
    mv "$tmp" "$latest"
    # shellcheck disable=SC2012 # names are our own timestamps
    ls -1 "$WB_SAVE_DIR"/2*.tsv 2>/dev/null | sort -r | tail -n +"$(( WB_SAVE_KEEP + 1 ))" | while IFS= read -r old; do rm -f "$old"; done
  fi
  [ "$auto" = 1 ] && return 0
  tmux set-option -g @wb_autosave 1 2>/dev/null || true
  echo "wb save: $(grep -c '^S' "$latest") sessions, $(grep -c $'^P\t.*\t\(claude\|attach\)\t' "$latest") Claude panes → $latest"
}

# _wb_restore_pane_cmd <pane fields…> — set REPLY to what to type into a
# restored pane, or "" for a plain shell. A conversation that is still live
# somewhere isn't resumed a second time.
_wb_restore_pane_cmd() {
  local cwd="$1" kind="$2" sid="$3" ccwd="$4" perm="$5" extra="$6" cd=""
  REPLY=""
  case "$kind" in
    nvim) REPLY="nvim${extra:+ $extra}" ;;
    claude|attach)
      [ -n "$sid" ] || return 0
      if [ "$kind" = attach ] && [ -n "${WB_REG_BY_JOB[$extra]:-}" ]; then
        REPLY="claude attach $extra"; return 0
      fi
      if [ -n "${WB_REG_BY_SID[$sid]:-}" ]; then
        echo "wb restore: $sid is already running; not resuming it twice" >&2
        return 0
      fi
      [ -z "$ccwd" ] || [ "$ccwd" = "$cwd" ] || cd="cd $(printf '%q' "$ccwd") && "
      wb_claude_args "$perm"
      REPLY="${cd}claude --resume $sid${WB_CLAUDE_ARGS[*]:+ ${WB_CLAUDE_ARGS[*]}}" ;;
  esac
}

# cmd_restore [snapshot] — rebuild every session in the snapshot (the latest
# by default) that isn't already open, then arm the automatic save.
cmd_restore() {
  local file="${1:-$WB_SAVE_DIR/latest.tsv}" line made=0 skipped=0 claudes=0
  [ -f "$file" ] || { echo "wb restore: no snapshot at $file — run wb save first" >&2; return 1; }
  _wb_registry_load
  local -a rec
  local -A opts=() exists=() win_made=() active_win=() active_pane=()
  local sess s target wid

  while IFS= read -r line; do
    wb_tsv_split "$line" rec
    [ "${rec[0]}" = S ] || continue
    opts[${rec[1]}]="$line"
    tmux has-session -t "=${rec[1]}" 2>/dev/null && exists[${rec[1]}]=1
  done < "$file"

  while IFS= read -r line; do
    wb_tsv_split "$line" rec
    [ "${rec[0]}" = P ] || continue
    # P sess win wname layout wactive ww wh pidx pactive cwd kind sid ccwd perm extra
    sess="${rec[1]}"
    [ -z "${exists[$sess]:-}" ] || continue
    target="=$sess:${rec[2]}"
    if ! tmux has-session -t "=$sess" 2>/dev/null; then
      tmux new-session -d -s "$sess" -c "${rec[10]}" -x "${rec[6]}" -y "${rec[7]}"
      wid="$(tmux list-windows -t "=$sess:" -F '#{window_id}' | head -n1)"
      tmux move-window -s "$wid" -t "$target" 2>/dev/null || true
      tmux rename-window -t "$wid" "${rec[3]}"
      win_made[$sess:${rec[2]}]=1
      made=$(( made + 1 ))
    elif [ -z "${win_made[$sess:${rec[2]}]:-}" ]; then
      tmux new-window -d -t "$target" -n "${rec[3]}" -c "${rec[10]}"
      win_made[$sess:${rec[2]}]=1
    else
      tmux split-window -d -t "$target" -c "${rec[10]}"
      tmux select-layout -t "$target" "${rec[4]}" 2>/dev/null || true
    fi
    [ "${rec[5]}" = 1 ] && active_win[$sess]="${rec[2]}"
    [ "${rec[9]}" = 1 ] && active_pane[$sess:${rec[2]}]="${rec[8]}"
    _wb_restore_pane_cmd "${rec[10]}" "${rec[11]}" "${rec[12]}" "${rec[13]}" "${rec[14]}" "${rec[15]}"
    if [ -n "$REPLY" ]; then
      tmux send-keys -t "$target.${rec[8]}" "$REPLY" Enter
      [[ "$REPLY" == *claude* ]] && claudes=$(( claudes + 1 ))
    fi
  done < "$file"

  for s in "${!opts[@]}"; do
    if [ -n "${exists[$s]:-}" ]; then skipped=$(( skipped + 1 )); continue; fi
    tmux has-session -t "=$s" 2>/dev/null || continue
    wb_tsv_split "${opts[$s]}" rec
    [ -z "${rec[2]}" ] || tmux set-option -t "=$s:" @task "${rec[2]}" >/dev/null
    [ -z "${rec[3]}" ] || tmux set-option -t "=$s:" @wb_repo "${rec[3]}" >/dev/null
    [ -z "${rec[4]}" ] || tmux set-option -t "=$s:" @wb_slug "${rec[4]}" >/dev/null
    [ -z "${rec[5]}" ] || tmux set-option -t "=$s:" @wb_branch "${rec[5]}" >/dev/null
  done
  for s in "${!active_pane[@]}"; do tmux select-pane -t "=${s%:*}:${s##*:}.${active_pane[$s]}" 2>/dev/null || true; done
  for s in "${!active_win[@]}"; do tmux select-window -t "=$s:${active_win[$s]}" 2>/dev/null || true; done

  tmux set-option -g @wb_autosave 1 2>/dev/null || true
  echo "wb restore: $made sessions rebuilt, $claudes Claude conversations resumed, $skipped already open"
}
