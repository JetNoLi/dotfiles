# Mac wb follow-ups

Last updated 2026-11-04. Three code reviews of `feat/mac-picker-native-status` found these items. None of them blocked the branch. Its bugs and races were fixed on 2026-11-04. When an item is fixed, delete it from this page.

## Fragile assumptions

- The output of `claude --bg` and the `tmux` field in Claude's registry were learned by probing, not from documentation. A Claude Code update could change either one.
- The auto-clear's background-tasks guard reads `.background_tasks` from the Stop hook's stdin. A probe on 2026-11-02 confirmed the field: each entry has `type` (`shell`, `monitor`) and `status`. Its shape isn't documented, so a Claude Code update could change it.
- `_ac_input_pending` matches the exact bytes `capture-pane -e` prints around Claude's input line, tested only against synthetic screens. A change to Claude's UI fails safe, but turns auto-clear off without a word.
- The `wb_repo_list` cache is lost inside subshells. This makes things slower but not wrong.

## Tooling gaps

- No second AI model has reviewed this code. No cross-model reviewer is installed, and Node 18 is older than the version acpx needs.
