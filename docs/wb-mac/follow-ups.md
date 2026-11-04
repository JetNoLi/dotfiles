# Mac wb follow-ups

Last updated 2026-11-04. Three code reviews of `feat/mac-picker-native-status` found these items. None of them blocked the branch. Its bugs and races were fixed on 2026-11-04. When an item is fixed, delete it from this page.

## Fragile assumptions

- The output of `claude --bg` and the `tmux` field in Claude's registry were learned by probing, not from documentation. A Claude Code update could change either one.
- The auto-clear's background-tasks guard reads `.background_tasks` from the Stop hook's stdin. A probe on 2026-11-02 confirmed the field: each entry has `type` (`shell`, `monitor`) and `status`. Its shape isn't documented, so a Claude Code update could change it.
- `_ac_input_pending` matches the exact bytes `capture-pane -e` prints around Claude's input line, tested only against synthetic screens. A change to Claude's UI fails safe, but turns auto-clear off without a word.
- The `wb_repo_list` cache is lost inside subshells. This makes things slower but not wrong.

## /decide outside a wb task

The first real run of `/decide` was from a session that isn't a wb task.

- `decide-path` and `decide-open` both need a task, so the page had to be made by hand and nothing marked it as needing Jet. A way to name an answer file without a task would let it run anywhere.
- The skill makes the page under `$WB_STATE_DIR/decide/`, but the Artifact tool only publishes from the working directory or the session scratchpad, so the files had to be copied first. Section 4 of the skill should make them in one of those.
- The comment watch's auto-reply said the answers were being recorded before anything was. The skill already warns about it; the wording on the page could too.

## Tidy-ups

- Row colours are chosen by matching label text. They should key off the status value instead.
- `status.sh` repeats `wb_status_rank` inline.
- `_wb_cwd_repo` and `_wb_main_repo` repeat each other.

## Test gaps

- Context card states other than idle.
- `wb new` branching from `origin`.
- `wb_bootstrap`.
- `claude-hooks-merge.sh` given malformed JSON.
- The `tmux.conf` and `install.sh` wiring.
- Picker `ctrl-x` run against your own session.
- Picker opening with one row. This was checked by hand only, because it is an interactive fzf flag.
- Some tests rely on short sleeps and could be flaky.

## Tooling gaps

- No second AI model has reviewed this code. No cross-model reviewer is installed, and Node 18 is older than the version acpx needs.
