# family.sh — a family's shared state (KTD1, KTD5). The family root's task
# is the coordinator (KTD2); its file holds the `## Family decisions`. Every
# member's file holds its own `## Status` block. A worker's cross-task
# proposal starts in its own Decisions, with `status: proposed` and an
# `affects:` line, and waits on Jet until a family decision cites it with
# `from: <stem> / <title>` (KTD3).

# wb_family_root <stem> — walk parent: up to the root and print its stem.
# Fails on a parent: cycle. A parent with no task file ends the walk.
wb_family_root() {
  local cur="$1" parent
  local -A seen=()
  while :; do
    seen[$cur]=1
    parent="$(wb_task_get "$(wb_task_file_for_stem "$cur")" parent)"
    if [ -z "$parent" ] || [ "$parent" = "$cur" ] || ! wb_task_exists "$(wb_task_file_for_stem "$parent")"; then
      echo "$cur"; return 0
    fi
    [ -z "${seen[$parent]:-}" ] || return 1
    cur="$parent"
  done
}

# wb_family_members <stem> — the family's task files, root first, leaving
# out members that are done. Fails when the task has no family: no root,
# or a root with no member besides itself.
wb_family_members() {
  local root stem file
  local -a out=()
  root="$(wb_family_root "$1")" || return 1
  while IFS= read -r stem; do
    file="$(wb_task_file_for_stem "$stem")"
    [ "$stem" = "$root" ] || [ "$(wb_task_get "$file" status)" != "done" ] || continue
    out+=("$file")
  done < <(wb_family_tree "$root")
  [ "${#out[@]}" -ge 2 ] || return 1
  printf '%s\n' "${out[@]}"
}

# wb_family_view <mode> <file...> — the view (mode "view") or the number
# waiting on Jet (mode "count"), from the members' files, root first.
# Waiting: every family decision not in force, plus every worker proposal
# no family decision cites.
wb_family_view() {
  local mode="$1"; shift
  awk -v mode="$mode" '
    function stem(p) { sub(/.*\//, "", p); sub(/\.md$/, "", p); return p }
    function val(s) { sub(/^[a-z ]+:[ \t]*/, "", s); sub(/[ \t]+$/, "", s); return s }
    function norm(s) { gsub(/[ \t]+/, " ", s); sub(/^ /, "", s); sub(/ $/, "", s); return s }
    function trim(s) { sub(/^\n+/, "", s); sub(/\n+$/, "", s); return s }
    function blank(s) { return s !~ /[^ \t\n]/ }
    FNR == 1 { fi++; st[fi] = stem(FILENAME); body = ($0 != "---"); sec = ""; kind = "" ; if (!body) next }
    !body { if ($0 == "---") body = 1; next }
    /^## / { sec = $0; kind = ""; next }
    sec == "## Status" { stat[fi] = stat[fi] $0 "\n"; next }
    sec == "## Family decisions" && fi == 1 {
      if (/^### /) { n++; ft[n] = substr($0, 5); fs[n] = ""; kind = "fd" }
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
      for (i = 1; i <= n; i++) if (fs[i] != "in-force") waiting++
      for (i = 1; i <= w; i++) {
        isopen[i] = (ws[i] == "proposed" && wa[i] != "" && wa[i] != "[]" && !cited[norm(wstem[i] " / " wt[i])])
        if (isopen[i]) { waiting++; untaken++ }
      }
      if (mode == "count") { print waiting; exit }

      printf "Family of %s (the coordinator)\n\n== Waiting on Jet: %d ==\n", st[1], waiting
      shown = 0
      for (i = 1; i <= n; i++) if (fs[i] != "in-force") { printf "\n%s\n", trim(fb[i]); shown++ }
      if (!shown) print "\n(no proposed family decisions)"
      print "\n== In force =="
      shown = 0
      for (i = 1; i <= n; i++) if (fs[i] == "in-force") { printf "\n%s\n", trim(fb[i]); shown++ }
      if (!shown) print "\n(none yet)"
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
  mapfile -t WB_FAMILY < <(wb_family_members "$(wb_task_stem "$WB_TASK")")
  [ "${#WB_FAMILY[@]}" -ge 2 ] && return 0
  echo "wb $1: $(wb_task_stem "$WB_TASK") isn't in a family (no parent: task with other members)" >&2
  return 1
}

# cmd_family [--waiting] [--task …] [--session-id …] — print the family view,
# or only the number of decisions waiting on Jet. Prints nothing and fails
# when the task has no family.
cmd_family() {
  local mode=view
  _wb_entry_task family "$@" || return 1
  case "${WB_ARGS[*]:-}" in
    '') ;;
    --waiting) mode=count ;;
    *) echo "usage: wb family [--waiting] [--task <task>]" >&2; return 1 ;;
  esac
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

# wb_task_set_status <file> <body> — replace the `## Status` section, or add
# it after the title, before the first `## ` section.
wb_task_set_status() {
  WB_STATUS_BODY="$2" awk '
    BEGIN { body = ENVIRON["WB_STATUS_BODY"]; target = "## Status" }
    function put() { print target; print ""; print body; print ""; done = 1 }
    FNR == 1 { pass++; infm = ($0 == "---"); fm = 0 }
    pass == 1 { if ($0 == target) exists = 1; next }
    infm && fm < 2 { if ($0 == "---") fm++; print; next }
    exists && $0 == target { put(); skipping = 1; next }
    skipping && /^## / { skipping = 0 }
    skipping { next }
    !exists && !done && /^## / { put() }
    { print }
    END { if (!done) { print ""; put() } }
  ' "$1" "$1" > "$1.tmp.$$" && mv "$1.tmp.$$" "$1"
}
