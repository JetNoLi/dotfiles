# rows.sh — the picker's rows: live tmux sessions, their agent panes,
# background sessions, and dormant tasks, grouped and formatted (R2, R7).
#
# Every row is 13 tab-separated fields:
#   1 repo   2 label   3 [branch]   4 urgency rank   5 "icon label"
#   6 target pane   7 tmux session   8 ref (task file or dir)
#   9 kind: task | repo | agent | bg | sep   10 agent count
#   11 slug (a bg row's job id)   12 nesting marker   13 visit epoch
# The nesting marker is empty for a top-level row, "1" for a sibling, "cN"
# for a child at level N, "aN" for an agent pane under a level-N row.

WB_COL_REPO=16
WB_COL_BRANCH=12
WB_COL_AGE=4
WB_NEST_MAX=3

# wb_status_icon <status> — "icon\tlabel". Plain ASCII: symbol glyphs have
# unreliable cell widths across fonts and throw off the columns.
wb_status_icon() {
  case "$1" in
    needs-input) printf '!\tneeds you\n' ;;
    done)        printf '+\tfinished\n' ;;
    working)     printf '*\tworking\n' ;;
    *)           printf -- '-\tidle\n' ;;
  esac
}

# wb_session_urgency <session> — "rank\ticon label\ttarget\tcount" for the
# session's most urgent Claude pane, or the no-agent default.
wb_session_urgency() {
  local rows count rank target status icon label
  rows="$(wb_claude_panes "$1" | sort -n)"
  if [ -z "$rows" ]; then printf '3\t- no agent\t\t0\n'; return; fi
  count="$(grep -c . <<< "$rows")"
  IFS=$'\t' read -r rank target status _ <<< "$(head -n1 <<< "$rows")"
  IFS=$'\t' read -r icon label < <(wb_status_icon "$status")
  printf '%s\t%s %s\t%s\t%s\n' "$rank" "$icon" "$label" "$target" "$count"
}

# wb_agent_subrows <repo> <session> <ref> <branch> [visit] — one row per
# Claude pane of a multi-agent session, in pane order so a pane that starts
# waiting doesn't jump above its siblings. Sub-rows order by the owner's
# visit time.
wb_agent_subrows() {
  local repo="$1" session="$2" ref="$3" branch="$4" visit="${5:-0}"
  local rank target status task icon label
  while IFS=$'\t' read -r rank target status task _; do
    IFS=$'\t' read -r icon label < <(wb_status_icon "$status")
    printf '%s\t%s\t%s\t%s\t%s %s\t%s\t%s\t%s\tagent\t1\t\t\t%s\n' \
      "$repo" "$task" "$branch" "$rank" "$icon" "$label" "$target" "$session" "$ref" "$visit"
  done < <(wb_claude_panes "$session" | LC_ALL=C sort -t $'\t' -k2,2V)
}

# wb_live_session_row <session> [visit] — one row for a live tmux session: a
# wb task session shows its task's title and branch, any other session its
# name and its cwd's branch.
wb_live_session_row() {
  local session="$1" visit="${2:-0}" repo slug task_file branch label kind ref slug_out=""
  repo="$(tmux show -t "=$session:" -v @wb_repo 2>/dev/null || true)"
  slug="$(tmux show -t "=$session:" -v @wb_slug 2>/dev/null || true)"
  if [ -n "$repo" ] && [ -n "$slug" ]; then
    task_file="$(wb_session_task_file "$session")"
    if wb_task_exists "$task_file"; then
      branch="$(wb_task_get "$task_file" branch)"
      label="$(wb_task_title "$task_file")"; [ -n "$label" ] || label="$slug"
    else
      branch="$slug"; label="$slug"
    fi
    kind=task; ref="$task_file"; slug_out="$slug"
  else
    repo="$session"; label="$session"; kind=repo
    ref="$(tmux display-message -p -t "=$session:" '#{pane_current_path}' 2>/dev/null || true)"
    branch="$(git -C "$ref" branch --show-current 2>/dev/null || true)"
  fi
  local -a u; wb_tsv_split "$(wb_session_urgency "$session")" u
  printf '%s\t%s\t[%s]\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t\t%s\n' \
    "$repo" "$label" "$branch" "${u[0]}" "${u[1]}" "${u[2]}" "$session" "$ref" "$kind" "${u[3]}" "$slug_out" "${visit:-0}"
}

# _wb_real_lower <path> — the path with symlinks resolved, lowercased, for
# matching a session's cwd to a worktree on a case-insensitive filesystem.
_wb_real_lower() {
  local p; p="$(cd "$1" 2>/dev/null && pwd -P)" || p="$1"
  printf '%s\n' "${p,,}"
}

# _wb_cwd_repo <dir> — the repo name a directory belongs to (a worktree
# names its main repo).
_wb_cwd_repo() {
  local common
  common="$(git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || { basename "$1"; return; }
  common="${common%/.git}"
  basename "$common"
}

# wb_bg_rows — one row per background session not attached in a pane (an
# attached one is already its pane's row). A session belongs to the task
# whose claude_sessions: names its id, else the task whose worktree is its
# cwd.
wb_bg_rows() {
  local -A by_sid=() by_cwd=()
  local line id file wt rank icon label repo title branch ref
  local -a rec
  while IFS= read -r line; do
    wb_tsv_split "$line" rec
    file="${rec[0]}"
    for id in ${rec[7]//,/ }; do by_sid[${id%%@*}]="$file"; done
    [ -n "${rec[4]}" ] || continue
    wt="${rec[3]:-$(wb_task_repo_path "$file" 2>/dev/null)}/${rec[4]}"
    by_cwd[$(_wb_real_lower "$wt")]="$file"
  done < <(wb_task_read_all)

  local sid job name cwd status attached
  while IFS=$'\t' read -r sid job name cwd status attached; do
    [ -z "$attached" ] || continue
    file="${by_sid[$sid]:-${by_cwd[$(_wb_real_lower "$cwd")]:-}}"
    if [ -n "$file" ]; then
      repo="$(wb_task_get "$file" repo)"; branch="$(wb_task_get "$file" branch)"
      title="$(wb_task_title "$file")"; ref="$file"
    else
      repo="$(_wb_cwd_repo "$cwd")"; branch="$(git -C "$cwd" branch --show-current 2>/dev/null || true)"
      title="$name"; ref="$cwd"
    fi
    rank="$(wb_status_rank "$status")"
    IFS=$'\t' read -r icon label < <(wb_status_icon "$status")
    printf '%s\t%s\t[%s]\t%s\t%s %s\t\t\t%s\tbg\t1\t%s\t\t0\n' \
      "$repo" "${title:-$name}" "$branch" "$rank" "$icon" "$label" "$ref" "$job"
  done < <(wb_bg_sessions)
}

# collect_live_rows — one row per live tmux session, then the background rows.
collect_live_rows() {
  local line session attached
  wb_status_load
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    # "<last-attached> <name>": time first so a never-attached session's
    # empty time still splits cleanly.
    attached="${line%% *}"; session="${line#* }"
    [ -n "$session" ] && wb_live_session_row "$session" "$attached"
  done < <(tmux list-sessions -F '#{session_last_attached} #{session_name}' 2>/dev/null)
  wb_bg_rows
}

# wb_live_agent_count — every Claude in a pane or the background.
wb_live_agent_count() {
  local panes bg
  wb_status_load
  panes="$(wb_claude_panes | grep -c . || true)"
  bg="$(wb_bg_sessions | awk -F'\t' '$6 == ""' | grep -c . || true)"
  echo $(( panes + bg ))
}

# wb_parent_subrows <row|-> [marker] — the row(s) with field 12 set.
wb_parent_subrows() {
  local marker="${2:-1}"
  if [ "$1" = - ]; then cat; else printf '%s\n' "$1"; fi |
    awk -F'\t' -v OFS='\t' -v m="$marker" '{ $12 = m; print }'
}

# wb_emit_with_agents <row> [level] — the row, then its agent sub-rows when
# it has more than one Claude pane.
wb_emit_with_agents() {
  local row="$1" level="${2:-0}"
  printf '%s\n' "$row"
  local -a f; wb_tsv_split "$row" f
  [ "${f[9]:-0}" -gt 1 ] 2>/dev/null || return 0
  if [ "$level" -gt 0 ]; then
    wb_agent_subrows "${f[0]}" "${f[6]}" "${f[7]}" "${f[2]}" "${f[12]:-0}" | wb_parent_subrows - "a$level"
  else
    wb_agent_subrows "${f[0]}" "${f[6]}" "${f[7]}" "${f[2]}" "${f[12]:-0}"
  fi
}

# _wb_emit_family <idx> <level> <marker> — row <idx>, then every unconsumed
# row whose parent is its stem, one level deeper (capped at WB_NEST_MAX).
# Each row is marked consumed before recursing, so a parent: cycle ends where
# it closes. Reads the caller's rows/parent_of/stem_of/consumed.
_wb_emit_family() {
  local idx="$1" level="$2" marker="$3" row next j
  consumed[$idx]=1
  row="${rows[$idx]}"
  [ -n "$marker" ] && row="$(wb_parent_subrows "$row" "$marker")"
  wb_emit_with_agents "$row" "$level"
  [ -n "${stem_of[$idx]}" ] || return 0
  next=$(( level + 1 )); [ "$next" -le "$WB_NEST_MAX" ] || next="$WB_NEST_MAX"
  for j in "${!rows[@]}"; do
    [ -n "${consumed[$j]:-}" ] && continue
    [ "${parent_of[$j]}" = "${stem_of[$idx]}" ] || continue
    _wb_emit_family "$j" "$next" "c$next"
  done
}

# Printed before each block (a family, or a sibling group with its anchor)
# so wb_order_blocks can keep it together. \001 never opens a real row.
_WB_BLOCK_MARK=$'\001block'

# wb_order_blocks [each] — order the blocks: the one holding
# WB_PICKER_SESSION first, then repos by their most recently visited block,
# then blocks within a repo the same way. Urgency is never a key, so a
# status change never moves a row while the picker is open. "each" makes
# every row its own block (the dormant tab).
wb_order_blocks() {
  LC_ALL=C awk -F'\t' -v mark="$_WB_BLOCK_MARK" -v here="${WB_PICKER_SESSION:-}" -v each="${1:-}" '
    $0 == mark { open = 0; next }
    {
      if (!open || each != "") {
        nb++; open = 1; repo[nb] = $1; label[nb] = $2; bmax[nb] = 0; pin[nb] = 0
      }
      if ($13 + 0 > bmax[nb]) bmax[nb] = $13 + 0
      if (here != "" && $7 == here) pin[nb] = 1
      n++; line[n] = $0; blk[n] = nb
    }
    END {
      for (b = 1; b <= nb; b++)
        if (!pin[b] && bmax[b] > gmax[repo[b]] + 0) gmax[repo[b]] = bmax[b]
      for (i = 1; i <= n; i++) {
        b = blk[i]
        printf "%d\t%.0f\t%s\t%.0f\t%s\t%d\t%s\n", \
          (pin[b] ? 0 : 1), gmax[repo[b]] + 0, repo[b], bmax[b], label[b], b, line[i]
      }
    }' |
    LC_ALL=C sort -s -t $'\t' -k1,1n -k2,2nr -k3,3 -k4,4nr -k5,5 -k6,6n |
    cut -f7-
}

collect_combined_rows() { _collect_combined_blocks | wb_order_blocks; }

# _collect_combined_blocks — live rows, most recently visited first, emitted
# as families: each row climbs to its topmost live ancestor; rows sharing a
# parent that isn't live are siblings under the earliest-created one; each
# row pulls its live children in beneath it. A background row whose task has
# a live session nests under that session's row.
_collect_combined_blocks() {
  local -a rows=() f
  local line
  while IFS= read -r line; do rows+=("$line"); done \
    < <(collect_live_rows | LC_ALL=C sort -t $'\t' -k13,13nr -k1,1 -k2,2)

  local -A parent_of=() stem_of=() idx_of_stem=()
  local i ref stem parent
  for i in "${!rows[@]}"; do
    parent_of[$i]=""; stem_of[$i]=""
    wb_tsv_split "${rows[$i]}" f
    [ "${f[8]}" = task ] && wb_task_exists "${f[7]}" || continue
    stem="$(wb_task_stem "${f[7]}")"; parent="$(wb_task_get "${f[7]}" parent)"
    [ "$parent" != "$stem" ] || parent=""
    parent_of[$i]="$parent"; stem_of[$i]="$stem"
    [ -n "${idx_of_stem[$stem]:-}" ] || idx_of_stem[$stem]="$i"
  done
  for i in "${!rows[@]}"; do
    wb_tsv_split "${rows[$i]}" f
    [ "${f[8]}" = bg ] && wb_task_exists "${f[7]}" || continue
    stem="$(wb_task_stem "${f[7]}")"
    if [ -n "${idx_of_stem[$stem]:-}" ]; then
      parent_of[$i]="$stem"   # under its own task's session; no children of its own
    else
      parent="$(wb_task_get "${f[7]}" parent)"
      [ "$parent" != "$stem" ] || parent=""
      parent_of[$i]="$parent"; stem_of[$i]="$stem"; idx_of_stem[$stem]="$i"
    fi
  done

  local -A consumed=() climbed=()
  local j root up anchor anchor_created created
  local -a group fj
  for i in "${!rows[@]}"; do
    [ -n "${consumed[$i]:-}" ] && continue
    root="$i"; climbed=([$i]=1)
    while parent="${parent_of[$root]}"; [ -n "$parent" ]; do
      up="${idx_of_stem[$parent]:-}"
      [ -n "$up" ] && [ -z "${consumed[$up]:-}" ] && [ -z "${climbed[$up]:-}" ] || break
      climbed[$up]=1; root="$up"
    done

    parent="${parent_of[$root]}"
    group=()
    if [ -n "$parent" ] && [ -z "${idx_of_stem[$parent]:-}" ]; then
      for j in "${!rows[@]}"; do
        [ -n "${consumed[$j]:-}" ] && continue
        [ "${parent_of[$j]}" = "$parent" ] && group+=("$j")
      done
    fi
    if [ "${#group[@]}" -le 1 ]; then
      printf '%s\n' "$_WB_BLOCK_MARK"
      _wb_emit_family "$root" 0 ""
      continue
    fi

    anchor=""; anchor_created=""
    for j in "${group[@]}"; do
      wb_tsv_split "${rows[$j]}" fj
      created="$(wb_task_get "${fj[7]}" created)"
      if [ -z "$anchor" ] || { [ -n "$created" ] && { [ -z "$anchor_created" ] || [[ "$created" < "$anchor_created" ]]; }; }; then
        anchor="$j"; anchor_created="$created"
      fi
    done
    printf '%s\n' "$_WB_BLOCK_MARK"
    _wb_emit_family "$anchor" 0 ""
    for j in "${group[@]}"; do
      [ -n "${consumed[$j]:-}" ] || _wb_emit_family "$j" 1 "1"
    done
  done
}

# collect_dormant_rows <mode> — tasks with status doing or review (plus
# paused in search mode) that have a worktree and a Claude transcript but no
# live session: no tmux session working on them and no live Claude, in a
# pane or the background, whose cwd is their worktree. Field 13 holds the
# newest transcript's time.
collect_dormant_rows() {
  local mode="$1" now session tf line
  now="$(date +%s)"
  local -A live_files=() live_cwds=()
  while IFS= read -r session; do
    tf="$(wb_session_task_file "$session" 2>/dev/null)" && live_files[$tf]=1
  done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)
  wb_status_load
  while IFS= read -r line; do
    live_cwds[$(_wb_real_lower "$line")]=1
  done < <(wb_live_claude_cwds)

  local -a rec
  local file status repo rp worktree branch wt_abs newest age title rank
  while IFS= read -r line; do
    wb_tsv_split "$line" rec
    file="${rec[0]}"; status="${rec[1]}"; repo="${rec[2]}"; rp="${rec[3]}"; worktree="${rec[4]}"; branch="${rec[5]}"
    [ -z "${live_files[$file]:-}" ] || continue
    case "$status" in
      doing|review) ;;
      paused) [ "$mode" = search ] || continue ;;
      *) continue ;;
    esac
    [ -n "$worktree" ] || continue
    rp="${rp:-$(wb_task_repo_path "$file" 2>/dev/null)}" || continue
    wt_abs="$rp/$worktree"
    [ -z "${live_cwds[$(_wb_real_lower "$wt_abs")]:-}" ] || continue
    newest="$(wb_transcripts "$wt_abs" | head -n1 | cut -f2)"
    [ -n "$newest" ] || continue
    age=$(( (now - newest) / 86400 )); [ "$age" -ge 0 ] || age=0
    title="$(wb_task_title "$file")"; [ -n "$title" ] || title="$(wb_task_stem "$file")"
    case "$status" in doing) rank=0 ;; review) rank=1 ;; *) rank=2 ;; esac
    printf '%s\t%s\t[%s]\t%s\t~ %s %sd\t\t\t%s\ttask\t0\t%s\t\t%s\n' \
      "$repo" "$title" "$branch" "$rank" "$status" "$age" "$file" "$branch" "$newest"
  done < <(wb_task_read_all)
}

# _WB_AWK_TEXT — count, cut and pad by character, not byte, under LC_ALL=C:
# a character is a byte that isn't a UTF-8 continuation byte (\200-\277), so
# truncation never stops mid-sequence. Double-width glyphs count as one.
_WB_AWK_TEXT='
  function nch(s,    t) { t = s; return length(s) - gsub(/[\200-\277]/, "", t) }
  function cbytes(s, k,    p, len, c) {
    len = length(s); p = 0; c = 0
    while (c < k && p < len) {
      p++
      while (p < len && substr(s, p + 1, 1) ~ /[\200-\277]/) p++
      c++
    }
    return p
  }
  # ASCII "..." on purpose: some terminals draw "…" two columns wide.
  function pad(s, w,    n) {
    n = nch(s)
    if (n > w) return substr(s, 1, cbytes(s, w - 3)) "..."
    return s sprintf("%*s", w - n, "")
  }
  # padtail(s, w) — keeps the END of a too-long value (a branch says more by its tail).
  function padtail(s, w,    n) {
    n = nch(s)
    if (n > w) return "..." substr(s, cbytes(s, n - (w - 3)) + 1)
    return s sprintf("%*s", w - n, "")
  }
  function fit(s, w) { if (nch(s) > w) return substr(s, 1, cbytes(s, w - 3)) "..."; return s }
'

# wb_picker_name_width — what the list pane has left for NAME beside the 55%
# preview, after REPO, BRANCH, AGE and the separators (fzf's FZF_COLUMNS,
# else the terminal width less the picker's padding).
wb_picker_name_width() {
  local c="${FZF_COLUMNS:-}" w
  case "$c" in ''|*[!0-9]*) c="$(tput cols 2>/dev/null)"; case "$c" in ''|*[!0-9]*) c=160 ;; esac; c=$((c - 2)) ;; esac
  w=$(( c - 3 - c * 55 / 100 - WB_COL_REPO - WB_COL_BRANCH - WB_COL_AGE - 6 ))
  [ "$w" -ge 20 ] || w=20
  echo "$w"
}

# wb_format_for_display [<snapshot>] — prepend the padded, coloured display
# string as a new field 1 (fields 2-14 stay addressable for fzf binds). Status
# is the colour of REPO and NAME: needs you bold magenta, finished cyan,
# working yellow, idle grey; a dormant row by its task status (doing yellow,
# review cyan, paused grey). The session Jet is in is grey, tagged (here),
# never counts as needing Jet, and its family is closed off by a separator
# row (kind "sep") that every key ignores. Each repo name prints once per
# group except in search mode, where fzf can only match what is shown.
#
# <snapshot> (live tab only) gets "count\tN", then per row
# "pos\tsession\tneeds\there\ttarget\tkind", for `u`, the header count and
# the cursor restore. Written to a temp name and moved into place.
wb_format_for_display() {
  local snap="${1:-}" nw now
  nw="$(wb_picker_name_width)"
  printf -v now '%(%s)T' -1
  now="${WB_PICKER_NOW:-$now}"
  LC_ALL=C awk -F'\t' -v OFS='\t' -v wr="$WB_COL_REPO" -v wn="$nw" \
      -v wb="$WB_COL_BRANCH" -v wa="$WB_COL_AGE" -v now="$now" \
      -v once="$([ "${WB_PICKER_MODE:-}" = search ] && echo 0 || echo 1)" \
      -v snap="${snap:+$snap.$$.tmp}" "$_WB_AWK_TEXT"'
      function age(v,    dt) {
        if (v + 0 <= 0) return "-"
        dt = now - v
        if (dt < 60)    return "now"
        if (dt < 3600)  return int(dt / 60) "m"
        if (dt < 86400) return int(dt / 3600) "h"
        return int(dt / 86400) "d"
      }
      BEGIN {
        cur = ENVIRON["WB_PICKER_SESSION"]
        mg = "\033[1;35m"; ye = "\033[33m"; dim = "\033[90m"; cy = "\033[36m"; rs = "\033[0m"
      }
      {
        n++
        lbl = $5; sub(/^[^ ]+ /, "", lbl)
        dorm = ($7 == "" && $5 ~ /^~ /)
        hs = (!dorm && cur != "" && $7 == cur)
        # A multi-agent session lists its panes as sub-rows; only the sub-row
        # that waits counts, so `u` lands on the pane itself.
        nd = (!dorm && !hs && $4 != "" && $4 + 0 == 0 && ($9 == "agent" || $(10) + 0 <= 1))
        if (dorm) {
          w = lbl; sub(/ .*/, "", w)
          c = (w == "doing") ? ye : (w == "review") ? cy : dim
        } else if (lbl == "needs you") c = mg
        else if (lbl == "finished")   c = cy
        else if (lbl == "working")    c = ye
        else                          c = dim
        nest = $(12); lvl = 0
        if (nest ~ /^[ac][0-9]+$/) lvl = substr(nest, 2) + 0
        ind = ""; for (k = 1; k < lvl; k++) ind = ind "  "
        top = ($9 != "agent" && $12 == "")
        if (n > 1 && !split1 && top) { split1 = n; if (pinned) grp = "" }
        if (hs && !split1) pinned = 1
        pre = ""
        if ($9 == "agent") {
          if (lvl > 0) ind = ind "  "
          pre = ind " > "; rcell[n] = pad("", wr)
        } else {
          same = top ? ($1 == grp) : ($1 == prev)
          rcell[n] = pad((once && same) ? "" : $1, wr)
          if (top) grp = $1
          prev = $1
          if (nest == "1")      pre = " ~ "
          else if (nest ~ /^c/) pre = ind " |- "
        }
        txt = pre $2
        # Tags are cut around, never cut off: the name shortens instead.
        if (hs && $9 != "agent") ncell[n] = pad(fit(txt, wn - 7) " (here)", wn)
        else if ($9 == "bg")     ncell[n] = pad(fit(txt, wn - 5) " (bg)", wn)
        else                     ncell[n] = pad(txt, wn)
        br = $3; sub(/^\[/, "", br); sub(/\]$/, "", br)
        bcell[n] = padtail(br, wb)
        acell[n] = ($9 == "agent") ? pad("", wa) : pad(age($13), wa)
        if (hs) disp = dim rcell[n] "  " ncell[n] "  " bcell[n] "  " acell[n] rs
        else    disp = c rcell[n] rs "  " c ncell[n] rs "  " bcell[n] "  " acell[n]
        row[n] = disp OFS $0
        sess[n] = $7; ishere[n] = hs; isneed[n] = nd; tgt[n] = $6; kd[n] = $9
        if (nd) cnt++
      }
      END {
        line = ""; for (k = 0; k < wr + wn + wb + wa + 6; k++) line = line "─"
        sep = dim line rs OFS OFS OFS OFS OFS OFS OFS OFS OFS "sep" OFS 0 OFS OFS OFS 0
        m = 0
        for (i = 1; i <= n; i++) {
          m++; out[m] = row[i]; os[m] = sess[i]; on[m] = isneed[i] + 0; oh[m] = ishere[i] + 0; ot[m] = tgt[i]; ok[m] = kd[i]
          if (pinned && split1 && i == split1 - 1) {
            m++; out[m] = sep; os[m] = ""; on[m] = 0; oh[m] = 0; ot[m] = ""; ok[m] = "sep"
          }
        }
        for (i = 1; i <= m; i++) print out[i]
        if (snap != "") {
          print "count", cnt + 0 > snap
          for (i = 1; i <= m; i++) print i, os[i], on[i], oh[i], ot[i], ok[i] > snap
          close(snap)
        }
      }'
  [ -z "$snap" ] || mv -f "$snap.$$.tmp" "$snap" 2>/dev/null || true
}

# wb_column_header — the legend row, in the same widths as the data rows.
wb_column_header() {
  local nw; nw="$(wb_picker_name_width)"
  printf '\033[90m%-*s  %-*s  %-*s  %s\033[0m\n' \
    "$WB_COL_REPO" "REPO" "$nw" "NAME" "$WB_COL_BRANCH" "BRANCH" "AGE"
}

# render_rows <mode_file> <view_file> — the header plus the LIVE tab, built
# fresh, or the DORMANT tab from the cache _refresh_dormant writes (the
# dormant scan is too slow for the 3-second reload).
render_rows() {
  local view WB_PICKER_MODE
  view="$(cat "${2:-}" 2>/dev/null || echo live)"
  WB_PICKER_MODE="$(cat "${1:-}" 2>/dev/null || true)"
  export WB_PICKER_MODE
  wb_column_header
  if [ "$view" = dormant ]; then
    cat "${2}.cache" 2>/dev/null | wb_format_for_display
  else
    collect_combined_rows | wb_format_for_display "${2:+$2.snap}"
  fi
}
