# Mac wb follow-ups

Last updated 2026-11-04. Three code reviews of `feat/mac-picker-native-status` found the items this page tracked. The bugs, tidy-ups, test gaps and /decide gaps were all fixed on 2026-11-04. What's left are assumptions to watch when Claude Code updates, and one tooling gap. When an item is fixed, delete it from this page.

## Fragile assumptions

- The output of `claude --bg` and the `tmux` field in Claude's registry were learned by probing, not from documentation. A Claude Code update could change either one.
- The auto-clear's background-tasks guard reads `.background_tasks` from the Stop hook's stdin. A probe on 2026-11-02 confirmed the field: each entry has `type` (`shell`, `monitor`) and `status`. Its shape isn't documented, so a Claude Code update could change it.
- `_ac_input_pending` matches the exact bytes `capture-pane -e` prints around Claude's input line, tested only against synthetic screens. A change to Claude's UI fails safe, but turns auto-clear off without a word.
- The `wb_repo_list` cache is lost inside subshells. This makes things slower but not wrong.

## Parked until they show up

Two picker changes from the work machine, left out on purpose on 2026-11-12. Port one only if its problem appears here.

- **Working while subagents run** (work PR #138). There, a Claude that hands work to background subagents ended its turn at once, so its row showed done while they ran. The fix tracks each subagent with `SubagentStart` and `SubagentStop` hooks. The Mac reads the registry's `busy` instead, and nobody has checked whether that stays busy while subagents run. Port it if a row shows done while its agents are still working.
- **Agent-count warning.** The work picker's header says "N agents live (warn >= M)". Worth it only if the number of live agents here grows well past the current eight.

## Tooling gaps

- No second AI model has reviewed this code. No cross-model reviewer is installed, and Node 18 is older than the version acpx needs.
