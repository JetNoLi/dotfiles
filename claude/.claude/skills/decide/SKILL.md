---
name: decide
description: Put a batch of decisions to Jet on the surface that fits, then record his answers in the wb task's Decisions section. Use when Jet types /decide, or when several questions need his answers at once, a run-and-paste loop is needed, or he asks for "a buffer" or "a page".
argument-hint: "[buffer | page] [topic]"
---

# /decide

Ask Jet several things at once, collect the answers, and record each one in
the task file. Every store write goes through `wb`
(`~/.config/scripts/tmux/wb`), which takes the task lock.

Arguments: `$ARGUMENTS`

## 1. Agree the direction in chat first

Before opening any surface, say in a few lines what is being decided and
which way you lean, and let Jet correct the framing. A surface built on the
wrong framing wastes his answers. Skip this only when Jet has just set the
direction himself.

A single question doesn't need a surface: ask it in chat.

## 2. Choose the surface

| The questions are… | Surface |
|---|---|
| a run-and-paste loop (Jet runs commands and pastes output) | buffer |
| a few quick answers, text only | buffer |
| options with diagrams, tables, code or evidence, or many items | page |
| a paste loop that needs visuals | both |

"A buffer" or "a page" in Jet's request overrides the table. If the session
isn't a wb task (`wb task-for-session` fails), say so: answers can't be
recorded, so ask in chat instead.

## 3. The buffer

1. Get a fresh answer file: `~/.config/scripts/tmux/wb decide-path`.
2. Write the questions into it with the Write tool, in one of the shapes in
   `references/buffer-shapes.md`. Each question states its default.
3. Run `~/.config/scripts/tmux/wb decide-buffer <file>` as a **background**
   Bash command (`run_in_background: true`). It opens nvim in a split of the
   task's tmux session, marks the task as needing Jet in the picker, and
   exits when he closes the split.
4. End the turn: tell Jet the buffer is open in the split and to save and
   quit (`:wq`) when done. Nothing else in the turn.
5. When the background command finishes (or Jet says done), read the file and
   go on to section 4, "Record the answers".

If the session is restarted while a buffer is open, the pick-up lists the
answer file under open /decide surfaces. Read it from there.

## 4. Record the answers

For each answered item, pipe a short entry to `wb decision` with the item's
title. Recording the same title again replaces the entry, so a corrected
answer never duplicates.

```bash
~/.config/scripts/tmux/wb decision "Which store format" <<'ENTRY'
**Answer:** B, markdown with frontmatter.
**Notes:** Jet's own words, verbatim, when he wrote any.
**Asked:** 2026-10-30, in the buffer.
ENTRY
```

- An item left blank takes its stated default. Record it as "default taken".
- Name any item Jet couldn't answer or questioned, and ask about it in chat.
- When every item from a surface is recorded, clear that surface:
  `~/.config/scripts/tmux/wb decide-clear <file or url>`. The picker stops
  showing the task as needing Jet once every open surface is cleared.

Then say in one line what was recorded, and carry on with the work the
answers unblock.
