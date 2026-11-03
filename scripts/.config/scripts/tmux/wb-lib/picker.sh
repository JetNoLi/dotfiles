# picker.sh — the fzf picker (R2, R3): LIVE and DORMANT tabs, modal keys,
# the preview, and the actions behind each key. Rows come from rows.sh.
#
# fzf sees the display string as field 1 and the row's own fields as 2-14,
# so in binds {7} is the target pane, {8} the session, {9} the ref, {10} the
# kind and {12} the slug (a bg row's job id).

# --- tmux helpers -----------------------------------------------------------------

tmux_ensure_session() {
  tmux has-session -t "=$1" 2>/dev/null || tmux new-session -d -s "$1" -c "$2"
}

tmux_focus() {
  if [ -n "${TMUX:-}" ]; then tmux switch-client -t "=$1"; else tmux attach -t "=$1"; fi
}

tmux_attach_or_create() { tmux_ensure_session "$1" "$2"; tmux_focus "$1"; }

tmux_goto_pane() {
  local target="$1" session window
  session="${target%%:*}"; window="${target#*:}"; window="${window%%.*}"
  if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$session"
    tmux select-window -t "$session:$window"
    tmux select-pane -t "$target"
  else
    tmux attach -t "$session" \; select-window -t "$session:$window" \; select-pane -t "$target"
  fi
}

# _wb_hold <message> — show a message in the picker's terminal until a key is
# pressed; an execute() pane would otherwise be redrawn before it is read.
_wb_hold() { printf 'wb: %s — press any key ' "$1" >&2; read -rn1 || true; echo >&2; }

# --- tabs, modes and the header ------------------------------------------------------

# _refresh_dormant <mode_file> <view_file> — rebuild the DORMANT cache, in
# the live tab's order with the newest transcript standing in for the visit
# time. A no-op on the LIVE tab.
_refresh_dormant() {
  local view mode
  view="$(cat "${2:-}" 2>/dev/null || echo live)"
  [ "$view" = dormant ] || return 0
  mode="$(cat "$1" 2>/dev/null || echo normal)"
  collect_dormant_rows "$mode" | wb_order_blocks each > "${2}.cache"
}

# _toggle_view <mode_file> <view_file> — `tab`: flip LIVE and DORMANT, filling
# the dormant cache before the first render of that tab.
_toggle_view() {
  local cur; cur="$(cat "${2:-}" 2>/dev/null || echo live)"
  if [ "$cur" = live ]; then printf dormant > "$2"; else printf live > "$2"; fi
  _refresh_dormant "$1" "$2"
}

# wb_status_line <context> <view> [<snapshot>] — fzf's three-line --header:
# the tab with the needs-you count and agent total, the colour legend, and
# the keys for the current mode.
wb_status_line() {
  local ctx="${1:-normal}" view="${2:-live}" snap="${3:-}" hint label legend need="" rs=$'\033[0m'
  if [ "$ctx" = search ]; then
    hint='SEARCH: type to filter (includes paused) · esc back to normal'
  else
    local b=$'\033[1m' n0=$'\033[22m'
    hint="${b}j/k g/G${n0} move ${b}l/enter${n0} open ${b}h/q${n0} quit ${b}u${n0} needs-you ${b}n${n0} new ${b}p${n0} down"
    hint+=" ${b}r${n0} rename ${b}b${n0} break ${b}ctrl-x${n0} done ${b}ctrl-r${n0} reload ${b}tab${n0} view ${b}/${n0} search"
  fi
  if [ "$view" = dormant ]; then
    label=DORMANT
    legend=$'\033[33mdoing'"$rs"$' \033[36mreview'"$rs"$' \033[90mpaused'"$rs"
  else
    label=LIVE
    legend=$'\033[1;35mneeds you'"$rs"$' \033[36mfinished'"$rs"$' \033[33mworking'"$rs"$' \033[90midle'"$rs"$' \033[90m(here) you are here · (bg) background'"$rs"
    if [ -n "$snap" ]; then
      local tag="" n=""
      { IFS=$'\t' read -r tag n; } 2>/dev/null < "$snap" || true
      [[ "$tag" == count && "$n" =~ ^[0-9]+$ ]] && need="$n need you · "
    fi
  fi
  printf 'wb · %s · %s%s agents live\n%s\n%s' "$label" "$need" "$(wb_live_agent_count)" "$legend" "$hint"
}

_set_mode() { printf '%s' "$2" > "$1"; }

_mode_header() {
  wb_status_line "$(cat "${1:-}" 2>/dev/null || echo normal)" "$(cat "${2:-}" 2>/dev/null || echo live)" "${2:-}.snap"
}

# _next_needs <mode_file> <view_file> — `u`: pos() of the next row that needs
# Jet after the cursor, wrapping. Silent on DORMANT and in search mode, where
# the snapshot's positions don't match the filtered list.
_next_needs() {
  local mode view
  mode="$(cat "${1:-}" 2>/dev/null || echo normal)"
  view="$(cat "${2:-}" 2>/dev/null || echo live)"
  [ "$view" = live ] && [ "$mode" = normal ] || return 0
  awk -F'\t' -v cur="${FZF_POS:-0}" '
    NR > 1 && $3 == 1 { if (!first) first = $1; if (!nxt && $1 + 0 > cur + 0) nxt = $1 }
    END { p = nxt ? nxt : first; if (p) print "pos(" p ")" }
  ' "${2:-}.snap" 2>/dev/null || true
}

# _initial_pos <mode_file> <view_file> — run after every reload. The first
# time: the first row that needs Jet, else the row after Jet's own, else row
# 1. After that: back to the row the focus bind recorded, found by session
# and kind (and pane, for an agent sub-row), since a status change rewrites
# the line and strands fzf's --track.
_initial_pos() {
  local mode view snap="${2:-}.snap"
  mode="$(cat "${1:-}" 2>/dev/null || echo normal)"
  view="$(cat "${2:-}" 2>/dev/null || echo live)"
  [ "$view" = live ] && [ "$mode" = normal ] && [ -r "$snap" ] || return 0
  if [ ! -e "${2:-}.initpos" ]; then
    : > "${2:-}.initpos"
    awk -F'\t' '
      NR > 1 {
        n++; if ($3 == 1 && !need) need = $1; if ($4 == 1) here = $1
        if (here && $1 > here && $6 != "sep" && !after) after = $1
      }
      END { if (!n) exit; p = need ? need : after ? after : 1; print "pos(" p ")" }
    ' "$snap"
    return 0
  fi
  [ -s "${2:-}.focus" ] || return 0
  local -a fc; wb_tsv_split "$(cat "${2:-}.focus")" fc
  [ -n "${fc[0]:-}" ] || return 0
  awk -F'\t' -v s="${fc[0]}" -v t="${fc[1]:-}" -v k="${fc[2]:-}" '
    NR > 1 && ($2 "") == (s "") {
      if (!a) a = $1
      if (($6 "") == (k "") && (k != "agent" || ($5 "") == (t ""))) { c = $1; exit }
    }
    END { p = c ? c : a; if (p) print "pos(" p ")" }
  ' "$snap"
}

# --- preview ------------------------------------------------------------------------

wb_capture_pane() { tmux capture-pane -ep -t "$1" 2>/dev/null; }

# _preview <target> <ref> — the fallback preview: a live pane's bottom, a
# task's title and latest hand-written Handoff (Next first, Done last), a
# repo's git status, else "nothing to preview". Always exits 0, since fzf
# paints a failing preview as an error.
_preview() {
  local target="${1:-}" ref="${2:-}" out title st br
  if [ -n "$target" ]; then
    wb_capture_pane "$target" | awk -v n="${FZF_PREVIEW_LINES:-40}" '
      { line[NR] = $0; t = $0; gsub(/\033\[[0-9;?]*[A-Za-z]/, "", t); if (t ~ /[^ \t\r]/) last = NR }
      END { s = last - n + 1; if (s < 1) s = 1; for (i = s; i <= last; i++) print line[i] }
    '
  elif wb_task_exists "$ref"; then
    title="$(wb_task_title "$ref")"; [ -n "$title" ] || title="$(wb_task_stem "$ref")"
    st="$(wb_task_get "$ref" status)"; br="$(wb_task_get "$ref" branch)"
    wb_task_body "$ref" | awk -v title="$title" -v st="$st" -v br="$br" '
      /^## / { inh = ($0 ~ /^## Handoffs[ \t]*$/); keep = 0; next }
      !inh { next }
      /^### / { keep = ($0 !~ /\(auto\)[ \t]*$/); if (keep) { n = 0; ts = $2 " " $3 }; next }
      keep { body[++n] = $0 }
      function emit(f, style,    t) {
        if (!(f in txt) || done[f]) return
        done[f] = 1; t = txt[f]
        printf "\n%s%s\033[0m\n%s%s\033[0m\n", B, f, style, t
      }
      END {
        B = "\033[1m"; D = "\033[90m"
        printf "%s%s\033[0m\n", B, title
        meta = st; if (br != "") meta = meta " · " br; if (ts != "") meta = meta " · saved " ts
        if (meta != "") printf "%s%s\033[0m\n", D, meta
        cur = ""; inrun = 0; nf = 0; raw = ""
        for (i = 1; i <= n; i++) {
          l = body[i]
          if (inrun) { if (l ~ /^```/) inrun = 0; else if (l !~ /^[ \t]*$/) run = run (run != "" ? "; " : "") l; continue }
          if (l ~ /^```run/) { inrun = 1; continue }
          if (match(l, /^\*\*[^*]+:\*\*/)) {
            cur = substr(l, 3, RLENGTH - 5); order[++nf] = cur
            t = substr(l, RLENGTH + 1); sub(/^[ \t]+/, "", t); txt[cur] = t
            continue
          }
          if (l ~ /^[ \t]*$/) { if (raw != "") raw = raw "\n"; continue }
          if (cur != "") txt[cur] = txt[cur] "\n" l
          raw = raw (raw != "" ? "\n" : "") l
        }
        if (!nf) { if (raw != "") printf "\n%s\n", raw; exit }
        emit("Next", "")
        if (run != "") printf "\033[36mrun: %s\033[0m\n", run
        emit("In flight", "")
        for (i = 1; i <= nf; i++) if (order[i] != "Done") emit(order[i], "")
        emit("Done", D)
      }
    '
  elif [ -d "$ref" ] && git -C "$ref" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    out="$(git -C "$ref" -c color.status=always status -s 2>/dev/null)"
    printf '%s\n' "${out:-clean}"
  else
    echo "nothing to preview"
  fi
  return 0
}

_preview_label() {
  local target="${1:-}" ref="${2:-}"
  if [ -n "$target" ]; then printf ' pane '
  elif wb_task_exists "$ref"; then printf ' task '
  elif [ -d "$ref" ] && git -C "$ref" rev-parse --is-inside-work-tree >/dev/null 2>&1; then printf ' git status '
  else printf ' wb '
  fi
}

# wb_preview_cmd — the context card for a row with a Claude session (a pane,
# or a bg row's job id), else _preview. A card that exits 3 is only its
# state lines, so _preview follows it. fzf runs this with $SHELL, so it
# stays plain sh.
wb_preview_cmd() {
  printf '%s' "c=\$('$SELF' _card {7} {10} {12} {9}); rc=\$?;" \
    " [ -n \"\$c\" ] && printf '%s\\n\\n' \"\$c\";" \
    " if [ -z \"\$c\" ] || [ \"\$rc\" = 3 ]; then" \
    " '$SELF' _preview {7} {9}; fi"
}

# --- key actions ------------------------------------------------------------------

# _rename <session> <kind> <ref> — `r`: rename the tmux session, or a bg row's
# task (a background session has no tmux session to rename).
_rename() {
  local session="$1" kind="${2:-}" ref="${3:-}" new
  if [ "$kind" = bg ]; then
    wb_task_exists "$ref" || { _wb_hold "this background session has no task to rename"; return 0; }
    read -r -p "Rename task '$(wb_task_title "$ref")' to: " new
    [ -n "$new" ] && wb_task_set_title "$ref" "$new"
    return 0
  fi
  [ -n "$session" ] || return 0
  read -r -p "Rename '$session' to: " new
  [ -n "$new" ] || return 0
  tmux rename-session -t "=$session:" "$(wb_sanitize "$new")" || { _wb_hold "rename failed"; return 1; }
}

# _down <session> <kind> <ref> — `p`: wb down on the row. On the session the
# picker runs in, the session stays open (closing it would kill the picker).
_down() {
  local session="$1" kind="${2:-}" ref="${3:-}"
  if [ "$kind" = bg ]; then
    wb_task_exists "$ref" || { _wb_hold "this background session has no task to park"; return 0; }
    cmd_down "$(wb_task_stem "$ref")" || { _wb_hold "down failed"; return 1; }
    return 0
  fi
  [ -n "$session" ] || return 0
  if [ -n "${TMUX:-}" ] && [ "$session" = "$(tmux display-message -p '#S' 2>/dev/null)" ]; then
    cmd_down --keep-session "$session" || { _wb_hold "down failed"; return 1; }
    _wb_hold "not closing '$session' via p — it's your current session; run 'wb down' yourself once you're ready"
    return 0
  fi
  cmd_down "$session" || { _wb_hold "down failed"; return 1; }
}

# _break_out <target> <kind> — `b`: move a pane into a new session of its own.
# break-pane can't create its destination, so a scratch session is made and
# its window killed afterwards, by window id (never index: base-index varies).
_break_out() {
  local target="$1" kind="${2:-}" new created new_name scratch_win
  if [ "$kind" = bg ]; then _wb_hold "no pane to break out — this agent runs in the background"; return 0; fi
  [ -n "$target" ] || return 0
  read -r -p "Break '$target' into new session: " new
  [ -n "$new" ] || return 0
  new="$(wb_sanitize "$new")"
  tmux has-session -t "=$new" 2>/dev/null && { _wb_hold "session '$new' already exists"; return 1; }
  created="$(tmux new-session -d -P -F '#{session_name}|#{window_id}' -s "$new")" \
    || { _wb_hold "could not create session '$new'"; return 1; }
  new_name="${created%%|*}"; scratch_win="${created##*|}"
  if tmux break-pane -d -s "$target" -t "=$new_name:"; then
    tmux kill-window -t "$scratch_win"
  else
    tmux kill-session -t "=$new_name" 2>/dev/null
    _wb_hold "could not break '$target' into '$new_name'"
    return 1
  fi
}

# _new — `n`: prompt for a repo (default: the launching session's) and a
# slug; a blank slug opens a plain repo session.
_new() {
  local default_repo repo slug dir
  default_repo="$(tmux display-message -p '#{@wb_repo}' 2>/dev/null || true)"
  read -r -p "New — repo${default_repo:+ [$default_repo]}: " repo
  repo="${repo:-$default_repo}"
  [ -n "$repo" ] || { _wb_hold "a repo is required"; return 1; }
  read -r -p "New — slug (blank = plain session): " slug
  if [ -n "$slug" ]; then
    cmd_new "$repo" "$slug" || _wb_hold "wb new failed"
  else
    dir="$(wb_repo_resolve "$repo")" || { _wb_hold "no repo called '$repo'"; return 1; }
    tmux_attach_or_create "$repo" "$dir"
  fi
}

# _ctrl_x_done <wb done args...> — wb done from ctrl-x. become() hands
# stdout to fzf as the selection, so all output goes to the terminal, and a
# refusal is held there before the picker window closes. Fails after a
# refusal, so callers add nothing to it.
_ctrl_x_done() {
  cmd_done "$@" >&2 || { _wb_hold "done failed — the task is still open"; return 1; }
}

# _ctrl_x <kind> <session> <target> <ref> — `ctrl-x`: a task row asks, then
# runs wb done and closes the session; a repo row is killed; an agent row
# kills its pane. On the session the picker runs in, the session stays open.
_ctrl_x() {
  local kind="$1" session="$2" target="$3" ref="${4:-}" self=0 effect
  case "$kind" in
    task)
      if [ -n "$session" ]; then
        effect="Removes the worktree, marks the task done, and closes the session."
        if [ -n "${TMUX:-}" ] && [ "$session" = "$(tmux display-message -p '#S' 2>/dev/null)" ]; then
          self=1; effect="Removes the worktree and marks the task done; your current session stays open."
        fi
        _ctrl_x_confirm "$(wb_session_task_file "$session" 2>/dev/null || true)" "$session" "$effect" || return 0
        cd "$HOME" 2>/dev/null || true   # never tear down the worktree we stand in
        if [ "$self" = 1 ]; then
          _ctrl_x_done "$session" || return 0
          _wb_hold "not closing '$session' via ctrl-x — it's your current session"
        else
          _ctrl_x_done --close "$session" || return 0
        fi
      elif [ -n "$ref" ]; then
        _ctrl_x_confirm "$ref" "$(wb_task_stem "$ref")" "Removes the worktree (the branch stays) and marks the task done." || return 0
        _ctrl_x_done "$(wb_task_stem "$ref")" || return 0
      fi
      ;;
    bg)
      wb_task_exists "$ref" || { _wb_hold "this background session has no task to close"; return 0; }
      _ctrl_x_confirm "$ref" "$(wb_task_stem "$ref")" "Stops the background agent, removes the worktree and marks the task done." || return 0
      cd "$HOME" 2>/dev/null || true
      _ctrl_x_done "$(wb_task_stem "$ref")" || return 0
      ;;
    repo)  [ -n "$session" ] && tmux kill-session -t "=$session" 2>/dev/null ;;
    agent) [ -n "$target" ] && tmux kill-pane -t "$target" 2>/dev/null ;;
  esac
  return 0
}

# _ctrl_x_confirm <task-file> <name> <effect> — only y or Y goes ahead.
_ctrl_x_confirm() {
  local file="$1" name="$2" effect="$3" title="" ans=""
  if wb_task_exists "$file"; then name="$(wb_task_stem "$file")"; title="$(wb_task_title "$file")"; fi
  printf 'Close %s%s? %s [y/N] ' "$name" "${title:+ ($title)}" "$effect" >&2
  read -r -n 1 ans || true
  printf '\n' >&2
  case "$ans" in y|Y) return 0 ;; esac
  echo "wb: left $name as it was" >&2
  return 1
}

# _accept <selection> — what Enter does with the chosen row.
_accept() {
  local -a f; wb_tsv_split "$1" f
  local repo="${f[1]}" target="${f[6]}" session="${f[7]}" ref="${f[8]}" kind="${f[9]}" slug="${f[11]}"
  if [ -n "$target" ]; then
    tmux_goto_pane "$target"
  elif [ "$kind" = bg ]; then
    wb_bg_attach "$slug" "$ref"
  elif [ -n "$session" ]; then
    tmux_focus "$session"
  elif [ "$kind" = repo ]; then
    tmux_attach_or_create "$repo" "$ref"
  elif [ "$kind" = task ]; then
    cmd_resume "$ref"
  fi
}

# --- the picker -----------------------------------------------------------------------

picker() {
  # Globals, not locals: the EXIT trap runs after picker() has returned.
  mode_file="$(mktemp -t wb-mode.XXXXXX)"
  view_file="$(mktemp -t wb-view.XXXXXX)"
  echo normal > "$mode_file"
  echo live > "$view_file"
  trap 'rm -f "$mode_file" "$view_file" "$view_file".{cache,snap,focus,initpos}' EXIT

  # Pin the current session's family and freeze the clock for every fzf
  # child, so ages don't tick between 3-second reloads.
  WB_PICKER_SESSION="$(tmux display-message -p '#S' 2>/dev/null || true)"
  WB_PICKER_NOW="$(date +%s)"
  export WB_PICKER_SESSION WB_PICKER_NOW

  local rendered selection
  rendered="$(render_rows "$mode_file" "$view_file")"
  if [ "$(grep -c . <<< "$rendered")" -le 1 ]; then
    echo "wb: no live sessions found." >&2
    exit 0
  fi

  # NORMAL mode disables search so unbound keys do nothing; i or / searches.
  local navkeys='j,k,g,G,q,i,r,b,p,n,u,/'
  local R="reload-sync(\"$SELF\" render \"$mode_file\" \"$view_file\")"
  local H="transform-header(\"$SELF\" _mode-header \"$mode_file\" \"$view_file\")"
  selection="$(printf '%s\n' "$rendered" | fzf --ansi --track \
        --delimiter=$'\t' --with-nth=1 --header-lines=1 \
        --layout=reverse-list --pointer='>' \
        --height=100% --padding=6,1,2,1 \
        --prompt='NORMAL ' \
        --header="$(wb_status_line normal live "$view_file.snap")" \
        --no-sort \
        --preview "$(wb_preview_cmd)" \
        --preview-window 'right,55%,wrap,border-left' \
        --preview-label ' wb ' \
        --bind 'start:disable-search' \
        --bind "focus:transform-preview-label(\"$SELF\" _preview-label {7} {9})+execute-silent([ -z {8} ] || printf '%s\t%s\t%s\n' {8} {7} {10} > \"$view_file.focus\")" \
        --bind "load:reload(sleep 3; \"$SELF\" render \"$mode_file\" \"$view_file\")+refresh-preview+$H+transform(\"$SELF\" _initial-pos \"$mode_file\" \"$view_file\")" \
        --bind "u:transform(\"$SELF\" _next-needs \"$mode_file\" \"$view_file\")" \
        --bind 'j:down' --bind 'k:up' --bind 'g:first' --bind 'G:last' \
        --bind 'ctrl-d:half-page-down' --bind 'ctrl-u:half-page-up' \
        --bind 'l:accept' --bind 'h:abort' --bind 'q:abort' \
        --bind "ctrl-r:execute-silent(\"$SELF\" _refresh-dormant \"$mode_file\" \"$view_file\")+$R+refresh-preview" \
        --bind "tab:execute-silent(\"$SELF\" _toggle-view \"$mode_file\" \"$view_file\")+$R+$H" \
        --bind "r:execute(\"$SELF\" _rename {8} {10} {9})+$R+refresh-preview" \
        --bind "b:execute(\"$SELF\" _break-out {7} {10})+$R+refresh-preview" \
        --bind "p:execute(\"$SELF\" _down {8} {10} {9})+$R+refresh-preview" \
        --bind "n:become(\"$SELF\" _new)" \
        --bind "ctrl-x:become(\"$SELF\" _ctrl-x {10} {8} {7} {9})" \
        --bind "i:execute-silent(\"$SELF\" _set-mode \"$mode_file\" search)+unbind($navkeys)+enable-search+change-prompt(SEARCH )+$R+$H" \
        --bind "/:clear-query+execute-silent(\"$SELF\" _set-mode \"$mode_file\" search)+unbind($navkeys)+enable-search+change-prompt(SEARCH )+$R+$H" \
        --bind "esc:enable-search+clear-query+disable-search+execute-silent(\"$SELF\" _set-mode \"$mode_file\" normal)+rebind($navkeys)+change-prompt(NORMAL )+$R+$H")" || exit 0

  # A row always has tabs; anything else is stray output from a become().
  if [[ "$selection" == *$'\t'* ]]; then _accept "$selection"; fi
}
