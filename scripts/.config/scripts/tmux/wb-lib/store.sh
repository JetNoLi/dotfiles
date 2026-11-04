# store.sh — the task store seam (R14). Every task read and write in wb goes
# through these functions, so the planned Go store can replace this file
# without the picker or lifecycle changing. Records are markdown files in
# the Ubuntu store's format (R13): `key: value` frontmatter between the first
# two `---` lines, then a body of `## ` sections.

TASKS_DIR="${TASKS_DIR:-$HOME/tasks}"
CLAUDE_PROJECTS_DIR="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"

# wb_store_init — create the store and its template on first use.
wb_store_init() {
  mkdir -p "$TASKS_DIR"
  [ -f "$TASKS_DIR/TEMPLATE.md" ] || cp "$WB_DIR/wb-lib/TEMPLATE.md" "$TASKS_DIR/TEMPLATE.md"
}

# wb_sanitize <slug> — the display form used in session names and file
# names. tmux rewrites "." and ":" in session names, and a ":" in a name
# later handed to kill-session parses as session:window.
wb_sanitize() { local s="${1//\//-}"; s="${s//./-}"; echo "${s//:/-}"; }

# wb_task_file <repo> <slug> — the record path for a repo and display slug.
wb_task_file() { printf '%s/%s--%s.md\n' "$TASKS_DIR" "$1" "$2"; }

# wb_task_stem <file> — the record's "<repo>--<slug>" name.
wb_task_stem() { local s="${1##*/}"; echo "${s%.md}"; }

# wb_task_file_for_stem <stem>
wb_task_file_for_stem() { printf '%s/%s.md\n' "$TASKS_DIR" "$1"; }

# wb_task_files — every record in the store.
wb_task_files() {
  local f
  for f in "$TASKS_DIR"/*.md; do
    [ -f "$f" ] || continue
    case "${f##*/}" in TEMPLATE.md|README.md) continue ;; esac
    echo "$f"
  done
}

# wb_task_exists <file>
wb_task_exists() { [ -f "$1" ]; }

# wb_task_get <file> <key> — one frontmatter value, inline comment stripped
# (including the comment of a key that has no value).
wb_task_get() {
  awk -v key="$2" '
    NR == 1 && $0 != "---" { exit }
    /^---$/ { infm++; if (infm == 2) exit; next }
    infm == 1 && $0 ~ "^" key ":" {
      sub("^" key ":[ \t]*", ""); sub(/(^|[ \t]+)#.*$/, ""); sub(/[ \t]+$/, ""); print; exit
    }
  ' "$1"
}

# wb_task_set <file> <key> <value> — replace the key's line, keeping its
# inline comment, or insert it before the closing `---`. Later duplicates
# of the key are dropped. The value goes through ENVIRON because `awk -v`
# would decode a literal "\n" into a newline and inject a second line.
wb_task_set() {
  WB_FM_VALUE="$3" awk -v key="$2" '
    BEGIN { val = ENVIRON["WB_FM_VALUE"] }
    { lines[++n] = $0
      if ($0 ~ /^---$/) { infm++; if (infm == 1) s = n; else if (infm == 2 && !e) e = n } }
    END {
      for (i = s + 1; i < e; i++) if (lines[i] ~ ("^" key ":")) { first = i; break }
      for (i = 1; i <= n; i++) {
        line = lines[i]
        if (i > s && i < e && line ~ ("^" key ":")) {
          if (i == first) {
            c = ""; if (match(line, /[ \t]+#.*$/)) c = substr(line, RSTART)
            print key ": " val c
          }
          continue
        }
        if (!first && i == e) print key ": " val
        print line
      }
    }
  ' "$1" > "$1.tmp.$$" && mv "$1.tmp.$$" "$1"
}

# wb_task_title <file> — the first `# ` heading.
wb_task_title() { awk '/^# / { sub(/^# /, ""); print; exit }' "$1"; }

# wb_task_body <file> — the whole record, for readers that lay it out.
wb_task_body() { cat "$1"; }

# wb_task_set_title <file> <title> — replace the first `# ` heading.
wb_task_set_title() {
  WB_TITLE="$2" awk '!done && /^# / { print "# " ENVIRON["WB_TITLE"]; done = 1; next } { print }' "$1" \
    > "$1.tmp.$$" && mv "$1.tmp.$$" "$1"
}

# wb_task_read_all — one line per record:
# file, status, repo, repo_path, worktree, branch, parent, claude_sessions
# (tab-separated, empty fields kept), from a single awk pass over the store.
wb_task_read_all() {
  local -a files
  mapfile -t files < <(wb_task_files)
  [ "${#files[@]}" -gt 0 ] || return 0
  awk '
    function clip(s) { sub(/(^|[ \t]+)#.*$/, "", s); sub(/[ \t]+$/, "", s); return s }
    function val(k,   s) { s = $0; sub("^" k ":[ \t]*", "", s); return clip(s) }
    function emit() { printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", file, f["status"], f["repo"], f["repo_path"], f["worktree"], f["branch"], f["parent"], f["claude_sessions"] }
    FNR == 1 { if (NR > 1) emit(); file = FILENAME; infm = 0; done = 0; split("", f) }
    done { next }
    /^---$/ { infm++; if (infm == 2) done = 1; next }
    infm == 1 && match($0, /^(status|repo|repo_path|worktree|branch|parent|claude_sessions):/) {
      k = substr($0, 1, RLENGTH - 1); f[k] = val(k)
    }
    END { emit() }
  ' "${files[@]}"
}

# wb_task_seed <repo> <slug> <worktree_rel> <repo_path> [<parent_stem>] —
# find or create the record for repo+slug and print its path. A new record
# comes from the template with status doing; an existing one is returned
# as it is, except that a planned or paused task moves back to doing.
wb_task_seed() {
  local repo="$1" slug="$2" worktree_rel="$3" repo_path="$4" parent="${5:-}" file
  wb_store_init
  file="$(wb_task_file "$repo" "$(wb_sanitize "$slug")")"
  if [ ! -f "$file" ]; then
    awk -v repo="$repo" -v rp="$repo_path" -v branch="$slug" -v wt="$worktree_rel" \
        -v parent="$parent" -v created="$(date +%F)" -v title="${slug//-/ }" '
      /^---$/ { infm++; print; next }
      infm == 1 && /^status:/    { print "status: doing"; next }
      infm == 1 && /^repo:/      { print "repo: " repo; next }
      infm == 1 && /^repo_path:/ { print "repo_path: " rp; next }
      infm == 1 && /^branch:/    { print "branch: " branch; next }
      infm == 1 && /^worktree:/  { print "worktree: " wt; next }
      infm == 1 && /^parent:/ && parent != "" { print "parent: " parent; next }
      infm == 1 && /^created:/   { print "created: " created; next }
      infm == 2 && /^# Title/    { print "# " title; next }
      { print }
    ' "$TASKS_DIR/TEMPLATE.md" > "$file"
    grep -q '^repo_path:' "$file" || wb_task_set "$file" repo_path "$repo_path"
  else
    case "$(wb_task_get "$file" status)" in
      planned|paused) wb_task_set "$file" status doing ;;
    esac
  fi
  echo "$file"
}

# wb_task_repo_path <file> — the record's repo_path:, else the repo name
# through the resolver (records written on Ubuntu have no repo_path:).
wb_task_repo_path() {
  local p; p="$(wb_task_get "$1" repo_path)"
  if [ -n "$p" ]; then echo "$p"; else wb_repo_resolve "$(wb_task_get "$1" repo)"; fi
}

# wb_task_worktree_abs <file> — the record's worktree as an absolute path.
wb_task_worktree_abs() {
  local repo_path wt
  wt="$(wb_task_get "$1" worktree)"
  [ -n "$wt" ] || return 1
  repo_path="$(wb_task_repo_path "$1")" || return 1
  echo "$repo_path/$wt"
}

# wb_entry_demote — stdin to stdout with `##` and `###` headings pushed down
# to `####`, so an entry body can't open a section or a sibling entry. A `# `
# line, such as a shell comment in a fenced block, is left as written: only
# the task's title is read from one, and that comes before any entry.
wb_entry_demote() { sed -E 's/^#{2,3}( |$)/####\1/'; }

# wb_task_append_handoff <file> <source> <message> — an automatic entry,
# `### <date> — <source> (auto)`, from wb down, done and resume.
wb_task_append_handoff() { wb_task_append_entry "$1" "$2 (auto)" "$3"; }

# wb_task_append_entry <file> <label> <body> — `### <date> — <label>` at the
# end of the Handoffs section, creating the section before Decisions if
# needed (KTD6). The label types the entry: `checkpoint`, `from <stem>`, or
# `<verb> (auto)`.
wb_task_append_entry() {
  local body
  body="### $(date '+%Y-%m-%d %H:%M') — $2"$'\n\n'"$(printf '%s\n' "$3" | wb_entry_demote)"
  WB_APPEND_BODY="$body" awk '
    BEGIN { body = ENVIRON["WB_APPEND_BODY"]; target = "## Handoffs" }
    FNR == 1 { pass++; prev = "" }
    pass == 1 { if ($0 == target) exists = 1; next }
    $0 == target { insection = 1 }
    insection && /^## / && $0 != target && !done {
      if (prev != "") print ""
      print body; print ""; done = 1; insection = 0
    }
    $0 == "## Decisions" && !exists && !done { print target; print ""; print body; print ""; done = 1 }
    { print; prev = $0 }
    END {
      if (!done) {
        if (prev != "") print ""
        if (!insection) { print target; print "" }
        print body
      }
    }
  ' "$1" "$1" > "$1.tmp.$$" && mv "$1.tmp.$$" "$1"
}

# wb_task_set_decision <file> <title> <body> — the Decisions entry
# `### <title>`, replaced in place when one has that title, else appended at
# the end of the section. A file without the section gets it before Done.
wb_task_set_decision() {
  local body
  body="### $2"$'\n\n'"$(printf '%s\n' "$3" | wb_entry_demote)"
  WB_DECISION_HEAD="### $2" WB_DECISION_BODY="$body" awk '
    BEGIN { head = ENVIRON["WB_DECISION_HEAD"]; body = ENVIRON["WB_DECISION_BODY"]; target = "## Decisions" }
    function put() { if (prev != "") print ""; print body; print ""; done = 1 }
    FNR == 1 { pass++; prev = "" }
    pass == 1 { if ($0 == target) exists = 1; if (exists && $0 == head) replace = 1; next }
    $0 == target { insection = 1; print; prev = $0; next }
    insection && skipping && /^###? / { skipping = 0 }
    insection && skipping { next }
    insection && replace && $0 == head && !done { put(); skipping = 1; next }
    insection && /^## / { insection = 0; if (!done) put() }
    !exists && !done && $0 == "## Done" { print target; print ""; print body; print ""; done = 1 }
    { print; prev = $0 }
    END {
      if (!done) {
        if (prev != "") print ""
        if (!insection) { print target; print "" }
        print body
      }
    }
  ' "$1" "$1" > "$1.tmp.$$" && mv "$1.tmp.$$" "$1"
}

# wb_task_pickup <file> — the latest checkpoint entry, then every Handoffs
# entry after it under "== Since this checkpoint ==". "Latest" is by
# position in the section, not by date (KTD6). Fails, printing nothing,
# when the task has no checkpoint.
wb_task_pickup() {
  awk '
    $0 == "## Handoffs" { insection = 1; next }
    insection && /^## / { insection = 0 }
    !insection { next }
    /^### / { n++; if ($0 ~ / — checkpoint$/) last = n }
    n { entry[n] = entry[n] $0 "\n" }
    END {
      if (!last) exit 1
      e = entry[last]; sub(/\n+$/, "\n", e); printf "%s", e
      if (last < n) {
        print ""; print "== Since this checkpoint =="
        for (i = last + 1; i <= n; i++) { e = entry[i]; sub(/\n+$/, "\n", e); print ""; printf "%s", e }
      }
    }
  ' "$1"
}

# wb_task_set_primary <file> <session_id> — make the session the record's
# @primary in claude_sessions, keeping the others. The caller holds the lock.
wb_task_set_primary() {
  local prev
  # The session's own older entry goes, so a repeated restart record doesn't grow.
  prev="$(wb_task_get "$1" claude_sessions | tr ',' '\n' | sed 's/@primary$//' \
    | awk -F@ -v sid="$2" '$1 != "" && $1 != sid' | paste -sd, -)" || true
  wb_task_set "$1" claude_sessions "$2@$(TZ=UTC date +%Y-%m-%dT%H:%M:%SZ)@primary${prev:+,$prev}"
}

# wb_session_task_file <session> — the record a tmux session works on: its
# @task option, else one derived from @wb_repo and @wb_slug.
wb_session_task_file() {
  local ref repo slug
  ref="$(tmux show -t "=$1:" -v @task 2>/dev/null || true)"
  if [ -n "$ref" ] && [ -f "$ref" ]; then echo "$ref"; return 0; fi
  repo="$(tmux show -t "=$1:" -v @wb_repo 2>/dev/null || true)"
  slug="$(tmux show -t "=$1:" -v @wb_slug 2>/dev/null || true)"
  [ -n "$repo" ] && [ -n "$slug" ] || return 1
  wb_task_file "$repo" "$(wb_sanitize "$slug")"
}

# --- families -----------------------------------------------------------------

# wb_family_tree <stem> — the stem, then each descendant depth-first, once.
wb_family_tree() {
  local -A kids=() out=()
  local line stem parent i
  local -a rec
  while IFS= read -r line; do
    wb_tsv_split "$line" rec
    stem="$(wb_task_stem "${rec[0]}")"; parent="${rec[6]}"
    [ -n "$parent" ] && [ "$parent" != "$stem" ] || continue
    kids[$parent]+=" $stem"
  done < <(wb_task_read_all)

  local -a stack=("$1") children=()
  while [ "${#stack[@]}" -gt 0 ]; do
    stem="${stack[-1]}"; unset 'stack[-1]'
    [ -z "${out[$stem]:-}" ] || continue
    out[$stem]=1
    printf '%s\n' "$stem"
    read -ra children <<< "${kids[$stem]:-}"
    for (( i = ${#children[@]} - 1; i >= 0; i-- )); do stack+=("${children[i]}"); done
  done
}

# --- Claude transcripts ---------------------------------------------------------
# Claude Code keeps one .jsonl per conversation under
# ~/.claude/projects/<cwd with every non-alphanumeric replaced by "-">.

wb_transcript_dir() {
  printf '%s/%s\n' "$CLAUDE_PROJECTS_DIR" "$(printf '%s' "$1" | LC_ALL=C tr -c 'A-Za-z0-9' '-')"
}

# wb_transcripts <worktree_abs> — "<id>\t<mtime>" per conversation, newest
# mtime first. Subagent transcripts in subdirectories are ignored.
wb_transcripts() {
  local dir f id; dir="$(wb_transcript_dir "$1")"
  for f in "$dir"/*.jsonl; do
    [ -f "$f" ] || continue
    id="${f##*/}"
    printf '%s\t%s\n' "${id%.jsonl}" "$(wb_mtime "$f")"
  done | sort -t $'\t' -k2,2nr
}

# wb_transcript_rank_key <path> <mtime> — when the conversation last had
# real activity: the timestamp of the last {"parentUuid": line in its final
# 256 KiB. Shutdown bookkeeping lines start {"type": and are skipped, since
# Claude stamps them on every transcript a dying process touched. Falls back
# to the mtime in the same shape.
wb_transcript_rank_key() {
  local ts
  ts="$(tail -c 262144 "$1" 2>/dev/null \
    | sed -n 's/^{"parentUuid":.*"timestamp":"\([^"]*\)".*/\1/p' | tail -n1)"
  if [ -n "$ts" ]; then echo "$ts"; else TZ=UTC printf '%(%Y-%m-%dT%H:%M:%S)T.000Z\n' "$2"; fi
}

# wb_resume_id <file> <worktree_abs> — the conversation `claude --resume`
# should open (KTD11): the record's @primary when its transcript exists,
# else the transcript with the newest activity. Empty when there is none.
wb_resume_id() {
  local dir primary id mtime
  dir="$(wb_transcript_dir "$2")"
  primary="$(wb_task_get "$1" claude_sessions | tr ',' '\n' | sed -n 's/^\([^@]*\)@.*@primary$/\1/p' | head -n1)"
  if [ -n "$primary" ] && [ -f "$dir/$primary.jsonl" ]; then echo "$primary"; return 0; fi
  while IFS=$'\t' read -r id mtime; do
    [ -n "$id" ] && printf '%s\t%s\n' "$(wb_transcript_rank_key "$dir/$id.jsonl" "$mtime")" "$id"
  done < <(wb_transcripts "$2") | sort -t $'\t' -k1,1r | head -n1 | cut -f2
}

# wb_sessions_snapshot <worktree_abs> [<primary_id>] — the claude_sessions:
# value, "<id>@<iso>[@primary],..." oldest first, for every transcript on
# disk. The caller supplies the primary id from the session registry, which
# is current when it is read, unlike a pane option set at the last prompt.
wb_sessions_snapshot() {
  local id mtime line
  local -a entries=()
  while IFS=$'\t' read -r id mtime; do
    [ -n "$id" ] || continue
    line="$id@$(TZ=UTC wb_epoch_to_date "$mtime" +%Y-%m-%dT%H:%M:%SZ)"
    [ -n "${2:-}" ] && [ "$id" = "$2" ] && line="$line@primary"
    entries+=("$line")
  done < <(wb_transcripts "$1" | sort -t $'\t' -k2,2n)
  local IFS=','
  echo "${entries[*]}"
}
