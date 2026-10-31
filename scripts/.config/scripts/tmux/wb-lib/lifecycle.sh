# lifecycle.sh — wb new, down, done, resume, and attaching to background
# sessions (R8, R10, R11, R15, R18). Task records go through store.sh; agent
# state comes from status.sh.

WB_GH_TIMEOUT="${WB_GH_TIMEOUT:-10}"     # seconds for the PR check in wb down
WB_GIT_TIMEOUT="${WB_GIT_TIMEOUT:-30}"   # seconds for fetches from origin

# --- worktrees ------------------------------------------------------------------

# wb_bootstrap <repo_dir> <worktree> — copy gitignored files a fresh worktree
# needs: those listed in the repo's .worktree-bootstrap, else its .env*
# files. Directories are symlinked; existing targets are left alone.
wb_bootstrap() {
  local repo_dir="$1" wt="$2" manifest="$1/.worktree-bootstrap" line f entry src dest rc=0
  local -a entries=()
  if [ -f "$manifest" ]; then
    while IFS= read -r line; do
      line="${line%%#*}"
      line="${line#"${line%%[![:space:]]*}"}"; line="${line%"${line##*[![:space:]]}"}"
      [ -n "$line" ] && entries+=("$line")
    done < "$manifest"
  else
    while IFS= read -r -d '' f; do entries+=("${f##*/}"); done \
      < <(find "$repo_dir" -maxdepth 1 -name '.env*' -print0 2>/dev/null)
  fi
  for entry in "${entries[@]}"; do
    src="$repo_dir/$entry"; dest="$wt/$entry"
    [ -e "$src" ] || continue
    { [ -e "$dest" ] || [ -L "$dest" ]; } && continue
    mkdir -p "$(dirname "$dest")" || { rc=1; continue; }
    if [ -d "$src" ]; then ln -s "$src" "$dest" || rc=1; else cp -a "$src" "$dest" || rc=1; fi
  done
  return "$rc"
}

# _wb_default_start <repo_dir> — origin's default branch, freshly fetched, as
# "origin/<name>"; empty (branch from HEAD) without a reachable origin.
_wb_default_start() {
  local def
  git -C "$1" remote get-url origin >/dev/null 2>&1 || return 0
  def="$(git -C "$1" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  def="${def#origin/}"
  [ -n "$def" ] || def="$(GIT_TERMINAL_PROMPT=0 wb_watchdog "$WB_GIT_TIMEOUT" git -C "$1" ls-remote --symref origin HEAD 2>/dev/null \
    | awk '$1 == "ref:" { sub("^refs/heads/", "", $2); print $2; exit }')"
  if [ -z "$def" ]; then
    echo "wb new: warning: could not find origin's default branch — branching from local HEAD" >&2
    return 0
  fi
  GIT_TERMINAL_PROMPT=0 wb_watchdog "$WB_GIT_TIMEOUT" git -C "$1" fetch -q origin "$def" 2>/dev/null \
    || echo "wb new: warning: git fetch origin $def failed — using the last-fetched origin/$def" >&2
  git -C "$1" show-ref --verify --quiet "refs/remotes/origin/$def" && echo "origin/$def"
  return 0
}

# _wb_add_worktree <repo_dir> <branch> <worktree> — an existing local branch
# is checked out; a new one branches from origin's default branch.
_wb_add_worktree() {
  local repo_dir="$1" branch="$2" wt="$3" elsewhere start
  git -C "$repo_dir" check-ref-format --branch "$branch" >/dev/null 2>&1 \
    || { echo "wb new: '$branch' is not a valid git branch name" >&2; return 1; }
  elsewhere="$(git -C "$repo_dir" worktree list --porcelain 2>/dev/null | awk -v ref="refs/heads/$branch" '
    $1 == "worktree" { sub(/^worktree /, ""); path = $0 }
    $1 == "branch" && $2 == ref { print path; exit }')"
  [ -z "$elsewhere" ] || { echo "wb new: branch '$branch' is already checked out at $elsewhere" >&2; return 1; }
  if git -C "$repo_dir" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$repo_dir" worktree add -q "$wt" "$branch"
    return
  fi
  start="$(_wb_default_start "$repo_dir")"
  if [ -n "$start" ]; then
    git -C "$repo_dir" worktree add -q --no-track -b "$branch" "$wt" "$start"
  else
    git -C "$repo_dir" worktree add -q -b "$branch" "$wt"
  fi
}

# --- sessions ---------------------------------------------------------------------

# wb_layout_session <session> <dir> <agent_cmd> — nvim, agent and shell
# windows. agent_cmd (a warm `claude --resume`) is typed into the agent
# window but not run. Windows are found by id and name, never index, since
# base-index differs between configs.
wb_layout_session() {
  local session="$1" dir="$2" agent_cmd="${3:-}" first
  first="$(tmux list-windows -t "=$session:" -F '#{window_id}' | head -n1)"
  tmux rename-window -t "$first" nvim
  tmux send-keys -t "$first" "nvim ."
  tmux new-window -d -t "=$session:" -n agent -c "$dir"
  tmux set-option -w -t "=$session:agent" remain-on-exit on
  [ -z "$agent_cmd" ] || tmux send-keys -t "=$session:agent" "$agent_cmd"
  tmux new-window -d -t "=$session:" -n shell -c "$dir"
  tmux select-window -t "$first"
}

# _wb_main_repo [dir] — the main checkout of the repo dir (or cwd) is in;
# a worktree resolves to its main repo.
_wb_main_repo() {
  local common
  common="$(git -C "${1:-.}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 1
  echo "${common%/.git}"
}

# _wb_open_task <repo> <repo_dir> <slug> <task_file|""> <parent> <bg> —
# the shared core of wb new and resume: worktree, record, tmux session.
# Leaves the record in WB_TASK and the session name in WB_SESSION.
_wb_open_task() {
  local repo="$1" repo_dir="$2" slug="$3" file="$4" parent="$5" bg="$6"
  local branch="$slug" wt_slug="$slug" wt_rel wt preset is_new=0 resume_cmd="" id
  if [ -n "$file" ] && wb_task_exists "$file"; then
    preset="$(wb_task_get "$file" branch)"; [ -z "$preset" ] || branch="$preset"
    preset="$(wb_task_get "$file" worktree)"
    case "$preset" in .worktrees/?*) wt_slug="${preset#.worktrees/}" ;; esac
  fi
  wt_rel=".worktrees/$wt_slug"; wt="$repo_dir/$wt_rel"
  WB_SESSION="$repo--$(wb_sanitize "$wt_slug")"

  [ -d "$wt" ] || _wb_add_worktree "$repo_dir" "$branch" "$wt" || return 1
  wb_bootstrap "$repo_dir" "$wt" || echo "wb new: warning: bootstrap into $wt failed (continuing)" >&2

  [ -n "$file" ] || file="$(wb_task_file "$repo" "$(wb_sanitize "$slug")")"
  wb_lock_acquire "$file" || return 75
  if wb_task_exists "$file"; then
    case "$(wb_task_get "$file" status)" in planned|paused) wb_task_set "$file" status doing ;; esac
    [ -n "$(wb_task_get "$file" worktree)" ] || wb_task_set "$file" worktree "$wt_rel"
  else
    file="$(wb_task_seed "$repo" "$slug" "$wt_rel" "$repo_dir" "$parent")"
  fi
  [ -n "$(wb_task_get "$file" repo_path)" ] || wb_task_set "$file" repo_path "$repo_dir"
  wb_lock_release "$file"

  tmux has-session -t "=$WB_SESSION" 2>/dev/null || is_new=1
  tmux_ensure_session "$WB_SESSION" "$wt"
  tmux set-option -t "=$WB_SESSION:" @wb_repo "$repo" >/dev/null
  tmux set-option -t "=$WB_SESSION:" @wb_slug "$wt_slug" >/dev/null
  tmux set-option -t "=$WB_SESSION:" @wb_branch "$branch" >/dev/null
  tmux set-option -t "=$WB_SESSION:" @task "$file" >/dev/null
  if [ "$is_new" = 1 ]; then
    if [ "$bg" = 0 ]; then
      id="$(wb_resume_id "$file" "$wt")"
      [ -z "$id" ] || resume_cmd="claude --resume $id"
    fi
    wb_layout_session "$WB_SESSION" "$wt" "$resume_cmd"
  fi
  WB_TASK="$file"
}

# _wb_registry_sid_for_job <job> — the full session id the registry records
# for a short job id, waiting up to ~3s for the file to appear.
_wb_registry_sid_for_job() {
  local f sid tries
  for tries in $(seq 30); do
    for f in "$CLAUDE_SESSIONS_DIR"/*.json; do
      [ -f "$f" ] || continue
      sid="$(jq -r --arg j "$1" 'select(.jobId == $j or ((.sessionId // "") | startswith($j))) | .sessionId' "$f" 2>/dev/null)"
      [ -n "$sid" ] && { echo "$sid"; return 0; }
    done
    sleep 0.1
  done
  return 1
}

# wb_claude_args <permission_mode> [prompt] — set WB_CLAUDE_ARGS to the
# flags and first prompt a relaunched Claude gets: the permission mode it
# ran in (default needs no flag), then the prompt.
wb_claude_args() {
  WB_CLAUDE_ARGS=()
  case "${1:-}" in ''|default) ;; *) WB_CLAUDE_ARGS+=(--permission-mode "$1") ;; esac
  [ -z "${2:-}" ] || WB_CLAUDE_ARGS+=("$2")
}

# wb_claude_pane_cmd <claude_bin> <permission_mode> <prompt> — the command a
# respawned agent pane runs (KTD2): Claude with its first prompt, then a
# shell once Claude exits, so the pane never closes under Jet.
wb_claude_pane_cmd() {
  wb_claude_args "$2" "$3"
  printf '%q ' "$1" "${WB_CLAUDE_ARGS[@]}"
  printf '; exec "${SHELL:-/bin/sh}"\n'
}

# _wb_start_bg <session> <worktree> <task_file> [prompt] [permission_mode] —
# start the agent as a background session (KTD6) and record its full session
# id as @primary. A prompt starts it working at once (KTD12). `claude --bg`
# prints a short id; attach and stop take that, the record keeps the full UUID.
_wb_start_bg() {
  local session="$1" wt="$2" file="$3" out job sid
  wb_claude_args "${5:-}" "${4:-}"
  out="$(cd "$wt" && claude --bg -n "$session" "${WB_CLAUDE_ARGS[@]}" 2>&1)" || { printf '%s\n' "$out" >&2; return 1; }
  job="$(sed -n 's/^backgrounded · \([^ ]*\) ·.*/\1/p' <<< "$out" | head -n1)"
  [ -n "$job" ] || { echo "wb new: couldn't read the session id from claude --bg:" >&2; printf '%s\n' "$out" >&2; return 1; }
  sid="$(_wb_registry_sid_for_job "$job")" || sid="$job"
  wb_lock_acquire "$file" || return 75
  wb_task_set_primary "$file" "$sid"
  wb_lock_release "$file"
  echo "wb new: $session's agent is running in the background ($job) — Enter on its row in the picker attaches"
}

# cmd_new [--bg [--handoff]] [--parent <stem>] [<repo>] <slug> — worktree
# at <repo>/.worktrees/<slug>, tmux session <repo>--<slug>, and a task
# record. With only a slug, the repo is the one the shell is in. --handoff
# (/handoff new, R10) reads a checkpoint from stdin, seeds the task with it
# and starts the background agent on its Next step without asking.
cmd_new() {
  local bg=0 handoff=0 seed="" parent="" repo="" slug repo_dir rc stem
  local -a args=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --bg) bg=1; shift ;;
      --handoff) handoff=1; shift ;;
      --parent)
        case "${2-}" in ''|--*) echo "wb new: --parent requires a value" >&2; return 1 ;; esac
        parent="$2"; shift 2 ;;
      -h|--help) echo "usage: wb new [--bg [--handoff]] [--parent <repo>--<slug>] [<repo>] <slug>"; return 0 ;;
      *) args+=("$1"); shift ;;
    esac
  done
  case "${#args[@]}" in
    1) slug="${args[0]}"
       repo_dir="$(_wb_main_repo)" || { echo "wb new <slug>: not inside a repo — pass 'wb new <repo> <slug>'" >&2; return 1; }
       repo="${repo_dir##*/}" ;;
    2) repo="${args[0]}"; slug="${args[1]}"
       rc=0; repo_dir="$(wb_repo_resolve "$repo")" || rc=$?
       case "$rc" in
         0) ;;
         2) return 1 ;;
         *) echo "wb new: no repo called '$repo' under $WB_REPO_ROOTS" >&2; return 1 ;;
       esac ;;
    *) echo "usage: wb new [--bg [--handoff]] [--parent <repo>--<slug>] [<repo>] <slug>" >&2; return 1 ;;
  esac
  [ -n "$slug" ] || { echo "wb new: <slug> must not be empty" >&2; return 1; }
  if [ "$handoff" = 1 ]; then
    [ "$bg" = 1 ] || { echo "wb new: --handoff needs --bg" >&2; return 1; }
    stem="$repo--$(wb_sanitize "$slug")"
    ! wb_task_exists "$(wb_task_file_for_stem "$stem")" \
      || { echo "wb new: $stem already exists — hand off to it with /handoff $stem" >&2; return 1; }
    _wb_read_body "new --handoff" || return 1
    seed="$WB_BODY"
  fi
  if [ -n "$parent" ]; then
    wb_task_exists "$(wb_task_file_for_stem "$parent")" || { echo "wb new: --parent '$parent' has no task record" >&2; return 1; }
    [ "$parent" != "$repo--$(wb_sanitize "$slug")" ] || { echo "wb new: --parent cannot be the task itself" >&2; return 1; }
  fi

  _wb_open_task "$repo" "$repo_dir" "$slug" "" "$parent" "$bg" || return 1
  if [ -n "$seed" ]; then
    # Seeded before Claude starts, so its startup hook finds the checkpoint
    # and the "start" marker (KTD12).
    wb_lock_acquire "$WB_TASK" || return 75
    wb_task_append_entry "$WB_TASK" checkpoint "$seed"
    wb_lock_release "$WB_TASK"
    wb_pickup_mark "$(wb_task_stem "$WB_TASK")" start
    _wb_start_bg "$WB_SESSION" "$repo_dir/$(wb_task_get "$WB_TASK" worktree)" "$WB_TASK" \
      "Pick up this task from its /handoff checkpoint."
  elif [ "$bg" = 1 ]; then
    _wb_start_bg "$WB_SESSION" "$repo_dir/$(wb_task_get "$WB_TASK" worktree)" "$WB_TASK"
  else
    tmux_focus "$WB_SESSION"
  fi
}

# cmd_resume <task_file|query> — rebuild a parked task's session with a warm
# `claude --resume` typed into the agent window (R15).
cmd_resume() {
  local file="$1" repo repo_dir branch
  wb_task_exists "$file" || file="$(_wb_find_task "$1" "wb resume")" || return 1
  repo="$(wb_task_get "$file" repo)"; branch="$(wb_task_get "$file" branch)"
  [ -n "$repo" ] && [ -n "$branch" ] || { echo "wb resume: $file has no repo: or branch:" >&2; return 1; }
  repo_dir="$(wb_task_repo_path "$file")" || { echo "wb resume: can't find the repo for $file" >&2; return 1; }
  _wb_open_task "$repo" "$repo_dir" "$branch" "$file" "" 0 || return 1
  wb_lock_acquire "$file" || return 75
  wb_task_append_handoff "$file" "wb resume" 'Session resumed via `wb resume`.'
  wb_lock_release "$file"
  tmux_focus "$WB_SESSION"
}

# _wb_find_task <query> <verb> — the one task whose stem contains <query>.
_wb_find_task() {
  local f stem
  local -a hits=()
  while IFS= read -r f; do
    stem="$(wb_task_stem "$f")"
    [[ "${stem,,}" == *"${1,,}"* ]] && hits+=("$f")
  done < <(wb_task_files)
  case "${#hits[@]}" in
    1) echo "${hits[0]}" ;;
    0) echo "$2: no task matches '$1'" >&2; return 1 ;;
    *) echo "$2: '$1' matches ${#hits[@]} tasks:" >&2
       for f in "${hits[@]}"; do echo "  $(wb_task_stem "$f")" >&2; done
       return 1 ;;
  esac
}

# --- background sessions ------------------------------------------------------------

# _wb_task_bg_jobs <task_file> — "<job>\t<session_id>" for each live
# background session belonging to the task: named by its claude_sessions:,
# or running in its worktree.
_wb_task_bg_jobs() {
  local wt sid job name cwd status attached ids
  wt="$(wb_task_worktree_abs "$1" 2>/dev/null)" && wt="$(_wb_real_lower "$wt")"
  ids=",$(wb_task_get "$1" claude_sessions | tr ',' '\n' | sed 's/@.*//' | paste -sd, -),"
  while IFS=$'\t' read -r sid job name cwd status attached; do
    if [[ "$ids" == *",$sid,"* ]] || { [ -n "$wt" ] && [ "$(_wb_real_lower "$cwd")" = "$wt" ]; }; then
      printf '%s\t%s\n' "$job" "$sid"
    fi
  done < <(wb_bg_sessions)
}

# _wb_stop_bg <task_file> — stop the task's background sessions (R18).
# Prints the last stopped session id, for the record's @primary. Fails
# when any session would not stop, so callers leave the task untouched.
_wb_stop_bg() {
  local job sid last="" failed=0
  while IFS=$'\t' read -r job sid; do
    if wb_watchdog 10 claude stop "$job" >/dev/null 2>&1 </dev/null; then
      last="$sid"
    else
      echo "wb: could not stop background session $job — it is still running" >&2
      failed=1
    fi
  done < <(_wb_task_bg_jobs "$1")
  echo "$last"
  return "$failed"
}

# wb_bg_attach <job> <task_file|cwd> — Enter on a bg row (R8). Jumps to a
# pane already attached to it; otherwise attaches in the task session's
# agent window (empty after --bg), or in a new window of the current
# session when the session belongs to no task.
wb_bg_attach() {
  local job="$1" ref="$2" ppid target session
  _wb_ps_load
  while read -r ppid target; do
    _wb_pane_claude_pid "$ppid" || continue
    [[ "${WB_PS_CMD[$REPLY]}" == *"claude attach $job"* ]] && { tmux_goto_pane "$target"; return 0; }
  done < <(tmux list-panes -a -F '#{pane_pid} #{session_name}:#{window_index}.#{pane_index}' 2>/dev/null)

  if wb_task_exists "$ref"; then
    session="$(wb_task_stem "$ref")"
    if tmux has-session -t "=$session" 2>/dev/null; then
      tmux list-windows -t "=$session:" -F '#{window_name}' | grep -qx agent \
        || tmux new-window -d -t "=$session:" -n agent -c "$(wb_task_worktree_abs "$ref")"
      tmux send-keys -t "=$session:agent" "claude attach $job" Enter
      tmux_goto_pane "$(tmux display -p -t "=$session:agent" '#{session_name}:#{window_index}.#{pane_index}')"
      return 0
    fi
    ref="$(wb_task_worktree_abs "$ref")"
  fi
  tmux new-window -n "bg-$job" -c "${ref:-$HOME}"
  tmux send-keys -t "bg-$job" "claude attach $job" Enter
}

# --- down and done ------------------------------------------------------------------

# _wb_resolve <verb> <arg> — set WB_SESSION and WB_TASK from a tmux session
# name, a task stem, or (no arg) the current session. WB_SESSION is empty
# when the task has no live tmux session.
_wb_resolve() {
  local verb="$1" arg="${2:-}"
  WB_SESSION=""; WB_TASK=""
  if [ -z "$arg" ]; then
    [ -n "${TMUX:-}" ] || { echo "wb $verb: run inside the task's session, or name it" >&2; return 1; }
    arg="$(tmux display-message -p '#S')"
  fi
  if tmux has-session -t "=$arg" 2>/dev/null; then
    WB_SESSION="$arg"
    WB_TASK="$(wb_session_task_file "$arg")" && wb_task_exists "$WB_TASK" \
      || { echo "wb $verb: $arg is not a wb task session" >&2; return 1; }
  else
    WB_TASK="$(wb_task_file_for_stem "$arg")"
    wb_task_exists "$WB_TASK" || { echo "wb $verb: '$arg' is no live session and no task" >&2; return 1; }
    tmux has-session -t "=$arg" 2>/dev/null && WB_SESSION="$arg"
  fi
  return 0
}

# _wb_has_open_pr <repo_dir> <branch> — gh under the watchdog (KTD9); a
# failure or timeout counts as no open PR.
_wb_has_open_pr() {
  local out
  out="$(cd "$1" && wb_watchdog "$WB_GH_TIMEOUT" gh pr list --head "$2" --state open --json number 2>/dev/null)" || {
    echo "wb: could not check PR status for '$2' — treating it as having no open PR" >&2
    return 1
  }
  grep -q '"number"' <<< "$out"
}

# _wb_agent_pane_sid <session> — the registry's session id for the agent
# window's pane.
_wb_agent_pane_sid() {
  local pane
  [ -n "$1" ] || return 0
  pane="$(tmux list-panes -s -t "=$1:" -F '#{window_name}|#{pane_id}' 2>/dev/null | awk -F'|' '$1 == "agent" { print $2; exit }')"
  [ -n "$pane" ] && wb_registry_pane_session_id "$pane"
  return 0
}

# cmd_down [--keep-session] [session|stem] — park a task: stop its
# background agent and tmux session, keep the worktree, and record its
# conversations so DORMANT can resume the right one. An open PR moves it
# to review.
cmd_down() {
  local keep=0 arg="" wt primary bg_sid snapshot review=0 repo_dir branch
  while [ $# -gt 0 ]; do
    case "$1" in --keep-session) keep=1 ;; *) arg="$1" ;; esac
    shift
  done
  _wb_resolve down "$arg" || return 1
  local file="$WB_TASK" session="$WB_SESSION"
  wt="$(wb_task_worktree_abs "$file")" || wt=""
  repo_dir="$(wb_task_repo_path "$file")" || repo_dir=""
  branch="$(wb_task_get "$file" branch)"

  primary="$(_wb_agent_pane_sid "$session")"
  bg_sid="$(_wb_stop_bg "$file")" || { echo "wb down: task left as it was; stop the agent, then re-run" >&2; return 1; }
  [ -z "$bg_sid" ] || primary="$bg_sid"
  snapshot="$(wb_sessions_snapshot "$wt" "$primary")"
  _wb_has_open_pr "$repo_dir" "$branch" && review=1

  wb_lock_acquire "$file" || return 75
  [ -z "$snapshot" ] || wb_task_set "$file" claude_sessions "$snapshot"
  [ "$review" = 0 ] || wb_task_set "$file" status review
  if [ "$keep" = 1 ]; then
    wb_task_append_handoff "$file" "wb down" 'Worktree kept, session left open (`wb down --keep-session`).'
  else
    wb_task_append_handoff "$file" "wb down" 'Session closed via `wb down` — worktree kept.'
  fi
  wb_lock_release "$file"

  [ "$keep" = 1 ] || rm -f "$(wb_needs_you_file "$(wb_task_stem "$file")")"
  [ "$keep" = 1 ] || [ -z "$session" ] || tmux kill-session -t "=$session" 2>/dev/null || true
  echo "wb down: $(wb_task_stem "$file") parked — worktree and record kept; resume it from DORMANT"
}

# _wb_family_close_target <parent_stem> — the nearest ancestor that isn't
# done, printed only when every one of its descendants is.
_wb_family_close_target() {
  local stem="$1" depth=0 s found
  local -A seen=()
  while [ -n "$stem" ] && [ "$depth" -lt 20 ] && [ -z "${seen[$stem]:-}" ] \
      && wb_task_exists "$(wb_task_file_for_stem "$stem")"; do
    if [ "$(wb_task_get "$(wb_task_file_for_stem "$stem")" status)" != done ]; then
      found=0
      while IFS= read -r s; do
        [ "$s" != "$stem" ] || continue
        found=1
        [ "$(wb_task_get "$(wb_task_file_for_stem "$s")" status)" = done ] || return 0
      done < <(wb_family_tree "$stem")
      [ "$found" = 1 ] && echo "$stem"
      return 0
    fi
    seen[$stem]=1; depth=$(( depth + 1 ))
    stem="$(wb_task_get "$(wb_task_file_for_stem "$stem")" parent)"
  done
}

# cmd_done [--close] [session|stem] — close a task: stop its background
# agent, refuse on uncommitted changes, remove the worktree (the branch
# stays), and mark the record done. --close also ends the tmux session.
# The removal is not forced, so anything an agent writes after the check
# is refused rather than lost; only a worktree that is still clean (its
# submodules are what git objects to) is forced.
cmd_done() {
  local close=0 arg="" wt repo_dir dirty note parent target
  while [ $# -gt 0 ]; do
    case "$1" in --close) close=1 ;; *) arg="$1" ;; esac
    shift
  done
  _wb_resolve done "$arg" || return 1
  local file="$WB_TASK" session="$WB_SESSION"
  wt="$(wb_task_worktree_abs "$file" 2>/dev/null)" || wt=""
  repo_dir="$(wb_task_repo_path "$file" 2>/dev/null)" || repo_dir=""

  if [ -n "$wt" ] && [ -d "$wt" ]; then
    dirty="$(git -C "$wt" status --porcelain 2>/dev/null || true)"
    if [ -n "$dirty" ]; then
      { echo "wb done: $wt has uncommitted changes:"; echo "$dirty"; echo "commit or stash, then re-run"; } >&2
      return 1
    fi
  fi
  _wb_stop_bg "$file" >/dev/null || { echo "wb done: task left open; stop the agent, then re-run" >&2; return 1; }
  if [ -n "$wt" ] && [ -d "$wt" ]; then
    cd "$HOME" 2>/dev/null || true
    if ! git -C "$repo_dir" worktree remove "$wt" 2>/dev/null; then
      dirty="$(git -C "$wt" status --porcelain --ignore-submodules=none 2>/dev/null)" || dirty="(git status failed)"
      if [ -n "$dirty" ]; then
        { echo "wb done: $wt changed while its agent stopped:"; echo "$dirty"; echo "commit or stash, then re-run"; } >&2
        return 1
      fi
      git -C "$repo_dir" worktree remove --force "$wt" || { echo "wb done: could not remove $wt" >&2; return 1; }
    fi
    note='Worktree removed'
  else
    note='Closed in the store only: no worktree to remove'
  fi
  [ "$close" = 1 ] && [ -n "$session" ] && note="$note, session closed"

  wb_lock_acquire "$file" || return 75
  wb_task_set "$file" status done
  wb_task_set "$file" closed "$(date +%F)"
  wb_task_set "$file" claude_sessions ""
  wb_task_append_handoff "$file" "wb done" "$note."
  wb_lock_release "$file"
  rm -f "$(wb_needs_you_file "$(wb_task_stem "$file")")"
  echo "wb done: $(wb_task_stem "$file") — $note, task done"

  parent="$(wb_task_get "$file" parent)"
  if [ -n "$parent" ]; then
    target="$(_wb_family_close_target "$parent")"
    [ -z "$target" ] || echo "wb done: every child of $target is done — close it with: wb done $target"
  fi
  if [ "$close" = 1 ] && [ -n "$session" ]; then tmux kill-session -t "=$session" 2>/dev/null || true; fi
  return 0
}
