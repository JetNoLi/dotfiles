# Mac wb follow-ups

Last updated 2026-10-29. Two code reviews of `feat/mac-picker-native-status` found these items. None of them blocked the branch, and none is fixed yet. When one is fixed, delete it from this page.

## Bugs and races

- **Lock takeover.** The mkdir lock in `wb-lib/compat.sh` (lines 23-36) has two edge cases. Two processes can both take over a stale lock at the same moment. A lock directory left behind with no pid file is never taken over, so every write waits until it times out.
- **Rename skips the lock.** `wb_task_set_title` in `wb-lib/store.sh` (the picker's `r` action) writes the task file without taking the lock, so it can race with another write.
- **`wb new --bg` starts the agent before taking the lock.** If the run fails after the start and is retried, a second background agent can start.
- **Empty fields shift columns.** `IFS=$'\t' read` merges consecutive tabs, so an empty field moves every field after it one place left. This affects `wb-lib/rows.sh:114` and `wb-lib/lifecycle.sh:263`, and it shows up as background sessions with no name being misread.
- **Renamed sessions are lost.** After a session is renamed, `wb_bg_attach` and `_wb_resolve` can't find it, so `wb down` and Enter on a background row fail.
- **Non-ASCII paths miss their transcripts.** Claude turns each byte of a multibyte character into a dash, and `wb_transcript_dir` turns each character into one, so the two folder names differ.
- **Picker `wb done` ignores its own errors.** `cmd_done` runs under `||` on the picker path, so `set -e` is off inside it. A failed task-file write still reports success.
- **Stale "still running" message.** It can appear after the job has already exited.

## Fragile assumptions

- The output of `claude --bg` and the `tmux` field in Claude's registry were learned by probing, not from documentation. A Claude Code update could change either one.
- The `wb_repo_list` cache is lost inside subshells. This makes things slower but not wrong.

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

- shellcheck isn't installed on the Mac, so `bash -n` is the only lint that has run.
- No second AI model has reviewed this code. No cross-model reviewer is installed, and Node 18 is older than the version acpx needs.

## Housekeeping

- Commit `b95066a` says agents stop before the dirty check, and `5b6f8a4` reverses that. Read the two together, or squash them before the PR.
- The uncommitted extended-keys lines in `tmux/.config/tmux/tmux.conf` and the nvim edits are waiting on Jet's decision.
- `gh` isn't authenticated, so `wb down` never moves a task to review. The check stays in place.
