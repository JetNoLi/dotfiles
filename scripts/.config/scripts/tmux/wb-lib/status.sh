# status.sh — agent status for every Claude in a tmux pane or the background
# (KTD3). Claude Code's session registry comes first; pane scraping is the
# fallback for panes the registry can't place. wb's own pane markers from
# claude-notify-hook.sh go on top, since the registry doesn't report a
# finished long turn or an open nvim decision buffer (R6).
#
# Statuses: needs-input (needs you), done (finished), working, idle.
# The registry and process table are read once per process; every picker
# refresh is a fresh `wb render`, so that is once per refresh.

CLAUDE_SESSIONS_DIR="${CLAUDE_SESSIONS_DIR:-$HOME/.claude/sessions}"

# --- process table -------------------------------------------------------------

declare -gA WB_PS_START=() WB_PS_CMD=() WB_PS_KIDS=()
WB_PS_LOADED=""

_wb_ps_load() {
  [ -z "$WB_PS_LOADED" ] || return 0
  WB_PS_LOADED=1
  local pid ppid d1 d2 d3 d4 d5 cmd
  while read -r pid ppid d1 d2 d3 d4 d5 cmd; do
    WB_PS_START[$pid]="$d1 $d2 $d3 $d4 $d5"
    WB_PS_CMD[$pid]="$cmd"
    WB_PS_KIDS[$ppid]+=" $pid"
  done < <(TZ=UTC LC_ALL=C ps -Ao pid=,ppid=,lstart=,command= 2>/dev/null)
}

# _wb_pane_claude_pid <pane_pid> — set REPLY to the Claude process in a pane:
# the pane's own process or one of its children whose argv[0] is claude.
# Keyed on the process tree because a Claude pane's pane_current_command is
# its version string, not "claude". Sets REPLY rather than printing so the
# per-pane loop doesn't fork.
_wb_pane_claude_pid() {
  local pid cmd
  for pid in "$1" ${WB_PS_KIDS[$1]:-}; do
    cmd="${WB_PS_CMD[$pid]:-}"
    cmd="${cmd%% *}"
    [ "${cmd##*/}" = claude ] && { REPLY="$pid"; return 0; }
  done
  return 1
}

# --- session registry -------------------------------------------------------------

declare -gA WB_REG_BY_PANE=() WB_REG_BY_JOB=() WB_REG_BY_SID=()
WB_REG_LOADED=""
WB_REG_ROWS=()

# _wb_registry_load — every live registry entry as
# "pid\tsessionId\tkind\tpane\tstatus\tcwd\tname\tjobId\tstatusUpdatedAt(ms)". An entry counts
# only while its pid is running with the same start time (procStart), so a
# reused pid never inherits a dead session. Files are fed through
# `fromjson?`, so a half-written one is skipped and the rest still load.
_wb_registry_load() {
  [ -z "$WB_REG_LOADED" ] || return 0
  WB_REG_LOADED=1
  command -v jq >/dev/null 2>&1 || return 0
  _wb_ps_load
  local f line pid start i
  local -a rec words
  while IFS= read -r line; do
    wb_tsv_split "$line" rec
    pid="${rec[0]}"
    read -r -a words <<< "${rec[8]}"   # ps pads single-digit days; compare word by word
    start="${words[*]}"
    [ -n "${WB_PS_START[$pid]:-}" ] && [ "${WB_PS_START[$pid]}" = "$start" ] || continue
    i="${#WB_REG_ROWS[@]}"
    WB_REG_ROWS+=("$(printf '%s\t' "${rec[@]:0:8}")${rec[9]}")
    [ -n "${rec[3]}" ] && WB_REG_BY_PANE[${rec[3]}]="$i"
    [ -n "${rec[7]}" ] && WB_REG_BY_JOB[${rec[7]}]="$i"
    WB_REG_BY_SID[${rec[1]}]="$i"
  done < <(
    for f in "$CLAUDE_SESSIONS_DIR"/*.json; do
      [ -f "$f" ] && printf '%s\n' "$(tr -d '\n' < "$f")"
    done | jq -rR 'fromjson? | select(type == "object" and .pid != null)
      | [(.pid | tostring), (.sessionId // ""), (.kind // ""),
         ((.tmux // "") | if test("\\.%[0-9]+$") then sub("^.*\\."; "") else "" end),
         (.status // ""), (.cwd // ""), (.name // ""), (.jobId // ""), (.procStart // ""),
         (.statusUpdatedAt // 0 | tostring)]
      | @tsv' 2>/dev/null
  )
}

# wb_registry_field <index> <n> — field n (0-based) of a loaded entry.
wb_registry_field() {
  local -a rec
  wb_tsv_split "${WB_REG_ROWS[$1]}" rec
  echo "${rec[$2]}"
}

# _wb_map_status <registry status> — set REPLY to wb's status. Unknown
# values (failed, stopped, anything new) read as idle until seen.
_wb_map_status() {
  case "$1" in
    waiting) REPLY=needs-input ;;
    busy)    REPLY=working ;;
    *)       REPLY=idle ;;
  esac
}

wb_status_rank() {
  case "$1" in needs-input) echo 0 ;; done) echo 1 ;; working) echo 2 ;; *) echo 3 ;; esac
}

# --- pane-scrape fallback ------------------------------------------------------------

# _wb_pane_awaiting_input <target> — a permission prompt on screen.
_wb_pane_awaiting_input() {
  local screen
  screen="$(tmux capture-pane -ep -t "$1" 2>/dev/null | tail -n 20)"
  ! grep -q -- '-- INSERT --' <<< "$screen" \
    && grep -qE 'Esc to cancel|Do you want to (proceed|run)' <<< "$screen"
}

# _wb_scrape_status <target> <title> <@claude_working> — set REPLY from the
# pane title glyph and screen, for a pane the registry has no entry for.
_wb_scrape_status() {
  local glyph="${2%% *}"
  case "$glyph" in
    ""|[A-Za-z0-9]*) REPLY=idle; return ;;
    ✳) ;;
    *) REPLY=working; return ;;
  esac
  if _wb_pane_awaiting_input "$1"; then REPLY=needs-input
  elif [ "$3" = 1 ]; then REPLY=working
  else REPLY=idle
  fi
}

# --- public -----------------------------------------------------------------------------

# wb_claude_panes [session] — one line per Claude pane, optionally in one
# session: "rank\ttarget\tstatus\ttask\tpane_id\tsession_id". A pane attached
# to a background session takes that session's registry status. Built once
# per process by wb_status_load.
WB_PANES_CACHE=""
WB_PANES_LOADED=""
wb_claude_panes() {
  wb_status_load
  [ -n "$WB_PANES_CACHE" ] || return 0
  if [ -z "${1:-}" ]; then
    printf '%s\n' "$WB_PANES_CACHE"
  else
    local line target
    while IFS= read -r line; do
      target="${line#*$'\t'}"; target="${target%%$'\t'*}"
      [ "${target%:*}" = "$1" ] && printf '%s\n' "$line"
    done <<< "$WB_PANES_CACHE"
  fi
  return 0
}

# wb_status_load — read the process table, the registry and every pane once.
# Callers that go on to ask from inside $(...) call this first, in their own
# shell, so the caches survive the subshells.
wb_status_load() {
  [ -z "$WB_PANES_LOADED" ] || return 0
  _wb_registry_load
  WB_PANES_CACHE="$(_wb_claude_panes_all)"
  WB_PANES_LOADED=1
}

_wb_claude_panes_all() {
  local sess win pidx pane ppid blocked working title target cpid cmd idx status task sid job rank
  local -a rec
  while IFS='|' read -r sess win pidx pane ppid blocked working title; do
    _wb_pane_claude_pid "$ppid" || continue
    cpid="$REPLY"
    target="$sess:$win.$pidx"
    idx="${WB_REG_BY_PANE[$pane]:-}"
    cmd="${WB_PS_CMD[$cpid]}"
    if [ -z "$idx" ] && [[ "$cmd" =~ ^[^\ ]*claude\ attach\ ([^\ ]+) ]]; then
      job="${BASH_REMATCH[1]}"
      idx="${WB_REG_BY_JOB[$job]:-}"
    fi
    sid=""
    if [ -n "$idx" ]; then
      wb_tsv_split "${WB_REG_ROWS[$idx]}" rec
      _wb_map_status "${rec[4]}"; sid="${rec[1]}"
    else
      _wb_scrape_status "$target" "$title" "$working"
    fi
    # wb's own markers win over either source, except needs-input over a
    # live registry entry: no hook clears it when a prompt is approved, and
    # the registry reports the prompt itself as waiting.
    case "$blocked" in
      "")          status="$REPLY" ;;
      done)        status=done ;;
      needs-input) if [ -n "$idx" ]; then status="$REPLY"; else status=needs-input; fi ;;
      *)           status=needs-input ;;
    esac
    case "$status" in needs-input) rank=0 ;; done) rank=1 ;; working) rank=2 ;; *) rank=3 ;; esac
    task="${title#* }"; [ "$task" != "$title" ] && [ -n "$task" ] || task="Claude Code"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$rank" "$target" "$status" "$task" "$pane" "$sid"
  done < <(tmux list-panes -a -F \
    '#{session_name}|#{window_index}|#{pane_index}|#{pane_id}|#{pane_pid}|#{@claude_blocked}|#{@claude_working}|#{pane_title}' 2>/dev/null)
}

# wb_bg_sessions — one line per live background session:
# "session_id\tjob_id\tname\tcwd\tstatus\tattached_target". attached_target
# is the pane running `claude attach` on it, or empty.
wb_bg_sessions() {
  _wb_registry_load
  local -A attached=()
  local rank target status task pane sid i
  local -a rec
  while IFS=$'\t' read -r rank target status task pane sid; do
    [ -n "$sid" ] && attached[$sid]="$target"
  done < <(wb_claude_panes)
  for i in "${!WB_REG_ROWS[@]}"; do
    wb_tsv_split "${WB_REG_ROWS[$i]}" rec
    [ "${rec[2]}" = bg ] && [ -z "${rec[3]}" ] || continue
    _wb_map_status "${rec[4]}"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "${rec[1]}" "${rec[7]}" "${rec[6]}" "${rec[5]}" \
      "$REPLY" "${attached[${rec[1]}]:-}"
  done
}

# wb_live_claude_cwds — the cwd of every live Claude the registry knows.
wb_live_claude_cwds() {
  _wb_registry_load
  local i
  for i in "${!WB_REG_ROWS[@]}"; do wb_registry_field "$i" 5; done | grep . || true
}

# wb_registry_entry_for_sid <session_id> — "status\tstatusUpdatedAt(ms)".
wb_registry_entry_for_sid() {
  _wb_registry_load
  local idx="${WB_REG_BY_SID[$1]:-}"
  [ -n "$idx" ] || return 1
  local -a rec
  wb_tsv_split "${WB_REG_ROWS[$idx]}" rec
  printf '%s\t%s\n' "${rec[4]}" "${rec[8]}"
}

# wb_registry_job_session_id <job_id> — a background session's full id.
wb_registry_job_session_id() {
  _wb_registry_load
  local idx="${WB_REG_BY_JOB[$1]:-}"
  [ -n "$idx" ] && wb_registry_field "$idx" 1
}

# wb_registry_pane_session_id <pane_id> — the live session id Claude reports
# for a pane, for wb down's @primary.
wb_registry_pane_session_id() {
  _wb_registry_load
  local idx="${WB_REG_BY_PANE[$1]:-}"
  [ -n "$idx" ] && wb_registry_field "$idx" 1
}
