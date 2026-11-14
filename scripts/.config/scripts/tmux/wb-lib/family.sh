# family.sh — a family's shared state (KTD1, KTD5). The family root's task
# is the coordinator (KTD2); its file holds the `## Family decisions`. Every
# member's file holds its own `## Status` block. A worker's cross-task
# proposal starts in its own Decisions, with `status: proposed` and an
# `affects:` line, and waits on Jet until a family decision cites it with
# `from: <stem> / <title>` (KTD3).

# _wb_family_root <stem> — REPLY: the family root, found by walking parent:
# up; a parent with no task file ends the walk. Fails on a parent: cycle or
# a stem with no task file. Needs _wb_family_load.
_wb_family_root() {
  local cur="$1" parent
  local -A seen=()
  [ -n "${_WBF_FILE[$cur]:-}" ] || return 1
  while parent="${_WBF_PARENT[$cur]}"; [ -n "$parent" ] && [ "$parent" != "$cur" ] && [ -n "${_WBF_FILE[$parent]:-}" ]; do
    seen[$cur]=1
    [ -z "${seen[$parent]:-}" ] || return 1
    cur="$parent"
  done
  REPLY="$cur"
}

# _wb_family_files_of <root> — WBF_OUT: the root's file, then each member's
# in wb_family_tree's order, leaving out members that are done. Fails when
# the root has no member besides itself. Needs _wb_family_load.
_wb_family_files_of() {
  local stem
  WBF_OUT=()
  _wb_family_walk "$1"
  for stem in "${WBF_WALK[@]}"; do
    if [ "$stem" = "$1" ] || [ "${_WBF_STATUS[$stem]}" != "done" ]; then WBF_OUT+=("${_WBF_FILE[$stem]}"); fi
  done
  [ "${#WBF_OUT[@]}" -ge 2 ]
}

# wb_family_members <stem> — the family's task files, root first, leaving
# out members that are done. Fails when the task has no family: a parent:
# cycle, or a root with no member besides itself.
wb_family_members() {
  _wb_family_load
  _wb_family_root "$1" || return 1
  _wb_family_files_of "$REPLY" || return 1
  printf '%s\n' "${WBF_OUT[@]}"
}

# wb_family_waiting <stem...> — for the picker: "<stem>\t<root>\t<count>"
# for each stem in a family, with the number waiting on Jet. One read of
# the store, and one of each family's files, however many stems share it.
wb_family_waiting() {
  local stem root
  local -A count=()
  _wb_family_load
  for stem in "$@"; do
    _wb_family_root "$stem" || continue
    root="$REPLY"
    if [ -z "${count[$root]+x}" ]; then
      count[$root]=""
      _wb_family_files_of "$root" && count[$root]="$(wb_family_view count "${WBF_OUT[@]}")"
    fi
    [ -z "${count[$root]}" ] || printf '%s\t%s\t%s\n' "$stem" "$root" "${count[$root]}"
  done
}

# wb_family_view <mode> <file...> — the view (mode "view") or the number
# waiting on Jet (mode "count"), from the members' files, root first.
# Waiting: every family decision neither in force nor declined, plus every
# worker proposal no family decision cites.
wb_family_view() {
  local mode="$1"; shift
  awk -v mode="$mode" '
    function stem(p) { sub(/.*\//, "", p); sub(/\.md$/, "", p); return p }
    function val(s) { sub(/^[a-z ]+:[ \t]*/, "", s); sub(/[ \t]+$/, "", s); return s }
    function norm(s) { gsub(/[ \t]+/, " ", s); sub(/^ /, "", s); sub(/ $/, "", s); return s }
    function trim(s) { sub(/^\n+/, "", s); sub(/\n+$/, "", s); return s }
    function blank(s) { return s !~ /[^ \t\n]/ }
    function closed(s) { return s == "in-force" || s == "declined" }
    FNR == 1 { fi++; st[fi] = stem(FILENAME); body = ($0 != "---"); sec = ""; kind = ""; if (!body) next }
    !body { if ($0 == "---") body = 1; next }
    /^## / { sec = $0; kind = ""; next }
    sec == "## Status" { stat[fi] = stat[fi] $0 "\n"; next }
    sec == "## Family decisions" && fi == 1 {
      if (/^### /) { n++; ft[n] = substr($0, 5); kind = "fd" }
      if (kind == "fd") {
        fb[n] = fb[n] $0 "\n"
        if (fs[n] == "" && /^status:/) fs[n] = val($0)
        if (/^from:/) cited[norm(val($0))] = 1
      }
      next
    }
    sec == "## Decisions" && fi > 1 {
      if (/^### /) { w++; wt[w] = substr($0, 5); wstem[w] = st[fi]; kind = "w"; next }
      if (kind == "w") {
        wb[w] = wb[w] $0 "\n"
        if (ws[w] == "" && /^status:/) ws[w] = val($0)
        if (/^affects:/) wa[w] = val($0)
      }
    }
    END {
      waiting = 0
      for (i = 1; i <= n; i++) if (!closed(fs[i])) waiting++
      for (i = 1; i <= w; i++) {
        isopen[i] = (ws[i] == "proposed" && wa[i] != "" && wa[i] != "[]" && !cited[norm(wstem[i] " / " wt[i])])
        if (isopen[i]) { waiting++; untaken++ }
      }
      if (mode == "count") { print waiting; exit }

      printf "Family of %s (the coordinator)\n\n== Waiting on Jet: %d ==\n", st[1], waiting
      shown = 0
      for (i = 1; i <= n; i++) if (!closed(fs[i])) { printf "\n%s\n", trim(fb[i]); shown++ }
      if (!shown) print "\n(no proposed family decisions)"
      print "\n== In force =="
      shown = 0
      for (i = 1; i <= n; i++) if (fs[i] == "in-force") { printf "\n%s\n", trim(fb[i]); shown++ }
      if (!shown) print "\n(none yet)"
      shown = 0
      for (i = 1; i <= n; i++) if (fs[i] == "declined") { if (!shown++) print "\n== Declined =="; printf "\n%s\n", trim(fb[i]) }
      print "\n== Status =="
      for (i = 1; i <= fi; i++) {
        printf "\n-- %s%s --\n", st[i], (i == 1 ? " (coordinator)" : "")
        print (blank(stat[i]) ? "(no status block)" : trim(stat[i]))
      }
      if (untaken) {
        print "\n== Not yet taken in by the coordinator =="
        for (i = 1; i <= w; i++) if (isopen[i]) printf "\n-- %s / %s --\n%s\n", wstem[i], wt[i], trim(wb[i])
      }
    }
  ' "$@"
}

# _wb_family_files <verb> — WB_FAMILY from WB_TASK's family; fails, saying
# why, when the task has none.
_wb_family_files() {
  local stem="${WB_TASK##*/}"
  mapfile -t WB_FAMILY < <(wb_family_members "${stem%.md}")
  [ "${#WB_FAMILY[@]}" -ge 2 ] && return 0
  echo "wb $1: ${stem%.md} isn't in a family (no parent: task with other members)" >&2
  return 1
}

# wb_family_edit <file...> — open the files in nvim, one tab each, root
# first, each at its family decisions, else its status block.
wb_family_edit() {
  local editor
  editor="$(command -v nvim)" || { echo "wb family: nvim isn't on the PATH" >&2; return 1; }
  "$editor" -p "$@" \
    -c "tabdo call cursor(1, 1) | if !search('^## Family decisions', 'cW') | call search('^## Status', 'cW') | endif | normal! zt" \
    -c tabfirst
}

# cmd_family [--waiting|--edit] [--task …] [--session-id …] — print the
# family view, only the number of decisions waiting on Jet, or open the
# members' files in nvim. The view and the count print nothing and fail
# when the task has no family; --edit says why.
cmd_family() {
  local mode=view
  _wb_entry_task family "$@" || return 1
  case "${WB_ARGS[*]:-}" in
    '') ;;
    --waiting) mode=count ;;
    --edit) mode=edit ;;
    *) echo "usage: wb family [--waiting|--edit] [--task <task>]" >&2; return 1 ;;
  esac
  if [ "$mode" = edit ]; then
    _wb_family_files family || return 1
    wb_family_edit "${WB_FAMILY[@]}"
    return
  fi
  _wb_family_files family 2>/dev/null || return 1
  wb_family_view "$mode" "${WB_FAMILY[@]}"
}

# cmd_family_decision <title> [--task …] [--session-id …] — stdin becomes
# the family decision with that title in the root's file, replacing an
# earlier one. Only the coordinator writes these (KD9); from a worker it
# warns and writes anyway, since nothing enforces the rules (KD8).
cmd_family_decision() {
  local root
  _wb_entry_task family-decision "$@" || return 1
  [ "${#WB_ARGS[@]}" -eq 1 ] && [ -n "${WB_ARGS[0]}" ] \
    || { echo "usage: wb family-decision <title> < body" >&2; return 1; }
  _wb_family_files family-decision || return 1
  root="${WB_FAMILY[0]}"
  [ "$root" = "$WB_TASK" ] || echo "wb family-decision: only the coordinator ($(wb_task_stem "$root")) writes family decisions; writing it there anyway" >&2
  _wb_read_body family-decision || return 1
  wb_lock_acquire "$root" || return 75
  wb_task_set_entry "$root" "## Family decisions" "${WB_ARGS[0]}" "$WB_BODY"
  wb_lock_release "$root"
}

# cmd_status [--task …] [--session-id …] — stdin becomes this task's
# `## Status` block, replacing the old one, with a fresh Updated: line.
cmd_status() {
  _wb_entry_task status "$@" || return 1
  [ "${#WB_ARGS[@]}" -eq 0 ] || { echo "usage: wb status < body" >&2; return 1; }
  _wb_read_body status || return 1
  WB_BODY="$(printf '%s\n' "$WB_BODY" | grep -v '^Updated:' | wb_entry_demote)"$'\n'"Updated: $(date '+%Y-%m-%d %H:%M')"
  wb_lock_acquire "$WB_TASK" || return 75
  wb_task_set_status "$WB_TASK" "$WB_BODY"
  wb_lock_release "$WB_TASK"
}
