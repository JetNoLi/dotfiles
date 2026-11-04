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

For both, open the buffer (section 3) and publish the page (section 4) in the
same turn; each is cleared on its own once its items are recorded.

"A buffer" or "a page" in Jet's request overrides the table. If the session
isn't a wb task (`wb task-for-session` fails), say so: answers can't be
recorded, so ask in chat instead.

## 3. The buffer

1. Get a fresh answer file: `~/.config/scripts/tmux/wb decide-path`.
2. Write the questions into it with the Write tool, in one of the shapes in
   `references/buffer-shapes.md`. Each question gives its options with their
   pros and cons, a recommendation, and its default.
3. Run `~/.config/scripts/tmux/wb decide-buffer <file>` as a **background**
   Bash command (`run_in_background: true`). It opens nvim in a split of the
   task's tmux session, marks the task as needing Jet in the picker, and
   exits when he closes the split.
4. End the turn: tell Jet the buffer is open in the split and to save and
   quit (`:wq`) when done. Nothing else in the turn.
5. When the background command finishes (or Jet says done), read the file and
   go on to section 5, "Record the answers".

If the session is restarted while a buffer is open or still has unanswered
items, the pick-up lists it under open /decide surfaces as
`buffer <answer file> <nvim pane>`. Read the answer file from there.

## 4. The page

A private claude.ai page. Answers save as Jet clicks, so he can stop halfway
and finish on his phone. Pages go to claude.ai, so use them only on the Mac,
which holds only personal repos.

1. Make the page's folder and copy the template:

   ```bash
   f=$(~/.config/scripts/tmux/wb decide-path); d=${f%.md}; mkdir -p "$d"
   cp "${CLAUDE_SKILL_DIR}/page/page.html" "$d/page.html"; echo "$d"
   ```

2. Write `$d/spec.json` with the Write tool, as `references/page-spec.md`
   describes. Use `items` when each question has its own options, and
   `verdicts` when every row takes one of the same answers. Then check it
   with `~/.config/scripts/tmux/wb decide-spec-check "$d/spec.json"` and fix
   whatever it names.
3. Set the page's name: replace `<title>Decisions</title>` in
   `$d/page.html` with the spec's title. The tag names the artifact.
4. Publish `$d/page.html` with the Artifact tool, with
   `files: {"spec.json": "$d/spec.json"}`,
   `capabilities: {"db": {}, "comments": {}}`, `icon: "checklist"` and a
   one-sentence description.
5. Mark it open: `~/.config/scripts/tmux/wb decide-open page <url>`.
6. End the turn with the link, one line on what's on it, and: "Press
   Submit when you're done. If I don't pick it up, type done."

Submit saves a `submitted` document and sends a comment to Claude from
Jet's click, which wakes this session while the page's watch has
auto-replies armed (`ArtifactComments` `watch` with no url lists them). When
the comment arrives or Jet types "done":

- Read the answers: `ArtifactData` `list` of the `answers` collection. Each
  document's id is an item id, holding `choice` (an option or verdict id) and
  an optional `note`. In the `verdicts` layout, an item with no document took
  its suggested verdict.
- Record them as in section 5. Reply in the comment's thread with one line
  saying what was recorded, then resolve the thread.
- A note asking for more information means the item is unanswered, even when
  the page counted its suggested verdict. Answer the question, then ask again.
- If items are still unanswered, name them and leave the page open.
- The watch's auto-reply posts a short note in the thread before this session
  gets its turn. It can't write to the task file, so whatever it says was
  "recorded" isn't. Record the answers yourself.

After a restart, the pick-up lists the page under open /decide surfaces. Run
`ArtifactComments` `watch` with its url, then check the listing. If
auto-replies aren't armed, tell Jet to type "done" after Submit.

## 5. Record the answers

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
