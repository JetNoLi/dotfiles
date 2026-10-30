---
name: handoff
description: Checkpoint the current wb task and hand it on. With no target, write a checkpoint and restart this session in a clean context that picks it up; with a task, pass the work to that task's live session; with `new <slug>`, start a seeded background task. Use when Jet types /handoff, or asks to checkpoint, save progress, carry on in a clean context, or pass work to another session.
argument-hint: "[--keep | <task> | new [<repo>] <slug>]"
---

# /handoff

One verb for handing work on. The task file in `~/tasks` is the record. A
checkpoint written there survives anything that happens to this session.

Every store write goes through `wb` (`~/.config/scripts/tmux/wb`), which takes
the task lock. Never edit a task file by hand.

Arguments: `$ARGUMENTS`

| Arguments | Destination | Sections |
|---|---|---|
| none, or `--keep` | this session, after a clean restart | 1, 2, 3 |
| `new [<repo>] <slug>` | a new background task | 1, 5 |
| anything else | the live session of that task | 1, 4 |

`new` counts only as the first argument, so a task called `new` is reached as
`<repo>--new`.

## 1. Find the task

```bash
~/.config/scripts/tmux/wb task-for-session
```

This prints the task file for this session, worked out from the tmux pane or
the session registry, never from the folder or branch. Its stem (the file name
without `.md`) is "this stem" below.

If it fails and there's no target, stop: nothing is written. Tell Jet this
session isn't a wb task, so there's no task to checkpoint. Handing off to
another task or a new one still works from outside a task.

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

## 4. Hand off to another task: `/handoff <task>`

The sender keeps going: nothing here clears or stops this session.

1. Write what the other task needs, not this session's whole checkpoint:
   what is being handed over, what is asked of it, and pointers to files,
   commits and plans. It must make sense with nothing but its own task file.
2. Write it into the target's task file:

   ```bash
   ~/.config/scripts/tmux/wb handoff-to <task> <<'ENTRY'
   **Handed over:** …
   **Asked:** …
   ENTRY
   ```

   `<task>` is a stem (`<repo>--<slug>`) or a part of one that matches a
   single task. The command prints the target's file. It refuses an unknown
   task and creates nothing.
3. Find the target's live session with `ListAgents`. It's the row named
   after the stem, or the row whose `tmux <session>:` is the stem.
4. If one is live, send it a short note with `SendMessage`, starting with a
   line that stands alone: "Handoff from <this stem>: read the newest
   `from <this stem>` entry under ## Handoffs in <file>, then act on it." Add
   one line saying what it's about. The message never interrupts a turn: a
   busy session reads it between steps, an idle one starts a turn.
5. If none is live, say the entry is written and waiting in its task file,
   and that the target isn't running.

## 5. Hand off to a new task: `/handoff new [<repo>] <slug>`

1. With no slug, pick a short kebab-case one from the work being handed over
   and say which.
2. Write the new task's first checkpoint: Done (the context it inherits),
   In flight, Next (the first step, specific enough to start on without
   asking), Open decisions.
3. Start it from this session's worktree, so the repo defaults to this one:

   ```bash
   ~/.config/scripts/tmux/wb new --bg --handoff --parent <this stem> [<repo>] <slug> <<'ENTRY'
   **Done:** …
   ENTRY
   ```

   Leave out `--parent` when this session isn't a wb task. `wb new` makes the
   worktree, tmux session and task, seeds the checkpoint, and starts a
   background Claude that begins on the Next step without asking.
4. Report the new task and its background job id. Its row shows in the
   picker, and Enter attaches.
