---
name: handoff
description: Checkpoint the current wb task and hand it on. With no target, write a checkpoint to this task's file and restart this session in a clean context that picks it up. Use when Jet types /handoff, or asks to checkpoint, save progress, or carry on in a clean context.
argument-hint: "[--keep]"
---

# /handoff

One verb for handing work on. The task file in `~/tasks` is the record. A
checkpoint written there survives anything that happens to this session.

Every store write goes through `wb` (`~/.config/scripts/tmux/wb`), which takes
the task lock. Never edit a task file by hand.

Arguments: `$ARGUMENTS`

## 1. Find the task

```bash
~/.config/scripts/tmux/wb task-for-session
```

This prints the task file for this session, worked out from the tmux pane or
the session registry, never from the folder or branch. If it fails, stop:
nothing is written. Tell Jet this session isn't a wb task, so there's no task
to checkpoint.

## 2. Write the checkpoint

Compose it from this conversation. A fresh session with none of this context
must be able to act on it.

```markdown
**Done:** what was completed this session, concretely.
**In flight:** what is partly done right now, with file paths.
**Next:** the one action to take on pick-up, specific enough to start on.
**Open decisions:** questions waiting on Jet, and where they wait (a buffer's
answer file or a page URL). Write "none" when there are none.
```

- Say "nothing yet" for an empty field rather than leaving it out.
- When Jet named the next command to run ("then run the review"), add it after
  **Next:** as a fenced `run` block holding exactly that command.
- Point at commits, plans and files rather than copying them in.
- Never put secrets in the entry.
- Open decisions: include every open `/decide` surface for this task, so a
  restarted session can still collect the answers. `wb pickup` lists them too.

Pipe the entry to `wb checkpoint` in one heredoc:

```bash
~/.config/scripts/tmux/wb checkpoint <<'ENTRY'
**Done:** …
ENTRY
```

## 3. Clear, unless `--keep`

- With `--keep`: stop here. Say the checkpoint is written and the
  conversation stays as it is.
- Otherwise run `~/.config/scripts/tmux/wb clear-request`. It arms the
  auto-clear: once this turn ends, the session restarts in a clean context and
  opens with the pick-up. End the turn with one line saying so, and nothing
  after it.
- If `clear-request` fails, the checkpoint is still written. Tell Jet to run
  `/clear`; the pick-up hook loads the checkpoint on his first message.

Don't type `/clear` into any pane or send keys to your own pane. The restart
belongs to the hook Jet installed.
