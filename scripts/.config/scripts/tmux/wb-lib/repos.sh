# repos.sh — find a repo by name the way session.sh does (KTD5): each root
# that is itself a repo, plus every repo a pruned .git search finds below a
# root. Override the roots with WB_REPO_ROOTS (colon-separated).

WB_REPO_ROOTS="${WB_REPO_ROOTS:-$HOME/dotfiles:$HOME/Desktop}"

# wb_repo_list — every repo across the roots, one "<name>\t<path>" per line.
# Searched once per process: the picker resolves a repo per dormant row.
WB_REPO_LIST_CACHE=""
wb_repo_list() {
  [ -n "$WB_REPO_LIST_CACHE" ] || WB_REPO_LIST_CACHE="$(_wb_repo_search)"
  [ -z "$WB_REPO_LIST_CACHE" ] || printf '%s\n' "$WB_REPO_LIST_CACHE"
}

_wb_repo_search() {
  local root roots
  IFS=: read -r -a roots <<< "$WB_REPO_ROOTS"
  for root in "${roots[@]}"; do
    [ -d "$root" ] || continue
    if [ -e "$root/.git" ]; then
      printf '%s\t%s\n' "${root##*/}" "$root"
    else
      fd --type d --prune -g -H '.git' "$root" -X dirname 2>/dev/null \
        | while IFS= read -r dir; do printf '%s\t%s\n' "${dir##*/}" "$dir"; done
    fi
  done | sort -u
}

# wb_repo_resolve <name> — print the repo's path. Returns 1 with no output
# when nothing matches, and 2 with every candidate listed when the name is
# ambiguous.
wb_repo_resolve() {
  local -a hits=()
  local name path
  while IFS=$'\t' read -r name path; do
    [ "$name" = "$1" ] && hits+=("$path")
  done < <(wb_repo_list)
  case "${#hits[@]}" in
    0) return 1 ;;
    1) printf '%s\n' "${hits[0]}" ;;
    *) {
         echo "wb: more than one repo is called '$1':"
         printf '  %s\n' "${hits[@]}"
       } >&2
       return 2 ;;
  esac
}
