# Mac wb follow-ups

Last updated 2026-11-01. Three code reviews of `feat/mac-picker-native-status` found these items. None of them blocked the branch, and none is fixed yet. When one is fixed, delete it from this page.

## Bugs and races

- **Lock takeover.** The mkdir lock in `wb-lib/compat.sh` (lines 23-36) has two edge cases. Two processes can both take over a stale lock at the same moment. A lock directory left behind with no pid file is never taken over, so every write waits until it times out.
- **`wb new --bg` starts the agent before taking the lock.** If the run fails after the start and is retried, a second background agent can start.
- **Renamed sessions are lost.** After a session is renamed, `wb_bg_attach` and `_wb_resolve` can't find it, so `wb down` and Enter on a background row fail.
- **Non-ASCII paths miss their transcripts.** Claude turns each byte of a multibyte character into a dash, and `wb_transcript_dir` turns each character into one, so the two folder names differ.
- **Picker `wb done` ignores its own errors.** `cmd_done` runs under `||` on the picker path, so `set -e` is off inside it. A failed task-file write still reports success.
- **Stale "still running" message.** It can appear after the job has already exited.
- **One task's sessions cancel each other's clear.** A prompt in a second Claude session mapped to the same task runs `_clear-cancel` and drops the first session's pending /handoff clear. It fails safe: no restart, and the checkpoint stays.
- **`wb_task_set_primary` keeps duplicates.** Making a session @primary that is already in `claude_sessions` leaves its old entry in the list as well, so a repeated restart record grows.

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

- shellcheck isn't installed on the Mac, so `bash -n` is the only lint that has run.
- No second AI model has reviewed this code. No cross-model reviewer is installed, and Node 18 is older than the version acpx needs.

## Housekeeping

- `gh` isn't authenticated, so `wb down` never moves a task to review. The check stays in place.
