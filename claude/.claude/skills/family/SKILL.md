---
name: family
description: The rules for a session whose wb task is in a family, as the coordinator or as a worker. Keeps leanings from passing as decisions, sends cross-task items to the coordinator, and keeps each task's status block current. Use when this session's task has a parent or children, when the family view is in context, or when Jet types /family.
---

# /family

A family is a wb task with child tasks (`parent:` in their frontmatter). The
root task's session is the **coordinator**. Every other member's session is a
**worker**. The coordinator alone writes the family decisions. Each session
writes only its own status block.

Every write goes through `wb` (`~/.config/scripts/tmux/wb`), which takes the
task lock. Never edit a task file by hand.

## 1. Find your role

```bash
~/.config/scripts/tmux/wb family
```

The first line names the coordinator. If that's this session's task, follow
sections 2 and 4. Otherwise follow sections 2 and 3. If it prints nothing,
this task isn't in a family and this skill doesn't apply.

Read the view when the session starts, and again before acting on any
decision a sibling might have changed.

## 2. Rules for every family session

- **Nothing is decided until Jet confirms it.** A decision starts as
  proposed. It comes into force only after you ask Jet, in so many words, to
  confirm it and Jet does. "I'm leaning towards X", "probably X" or "X makes
  sense" are leanings, not confirmations. Store Jet's reply verbatim with the
  decision.
- **Never pass on a proposed decision as decided.** Don't tell another
  session it is decided, and don't write it anywhere as decided.
- **Single-task decisions stay home.** A decision that affects only this
  task goes in its own Decisions with `wb decision`, as usual, with no
  `affects:` line.
- **Ask with options.** Put each decision to Jet with options, their pros
  and cons, and a recommendation. Use `/decide` for several at once.
- **End every turn with what you need from Jet.** The reply's last section is
  a `### Needs you` heading, then one line saying what you need, or
  "Nothing." The picker's preview reads it.

## 3. As a worker

**Keep your status block current.** Rewrite it whenever your phase, what
you're touching, or what you're holding changes:

```bash
~/.config/scripts/tmux/wb status <<'EOF'
Phase: building
Touching: scripts/.config/scripts/tmux/claude-family-hook.sh
Holding: the picker count, until "One family view" is in force
EOF
```

Phase is `planning`, `building` or `reviewing`. Holding is `nothing` when
nothing is held. `wb status` adds the `Updated:` line.

**A cross-task item goes to the coordinator.** When a decision, or a finding
that isn't a decision, would affect a sibling task:

1. Record it as proposed in this task, with the tasks it affects:

   ```bash
   ~/.config/scripts/tmux/wb decision "<short title>" <<'EOF'
   status: proposed
   affects: [dotfiles--family-picker]

   What it is and why it matters. Jet's words verbatim, if any.
   EOF
   ```

2. Tell Jet it belongs in the coordinator's session (name it from the view's
   first line), and don't settle it here.
3. Hold only the work that depends on it. Keep going on everything else, and
   say what's held on your Holding line.

It waits on Jet in the picker until the coordinator takes it in, even when
the coordinator isn't running. Don't message siblings about it.

**When a decision you hold on comes into force**, pick the held work back
up and clear the Holding line.

## 4. As the coordinator

Keep your own status block current too, as in section 3.

**Take in worker proposals.** Each one under "Not yet taken in by the
coordinator" in the view becomes a family decision. Judge its impact
yourself, and add any affected task the worker missed:

```bash
~/.config/scripts/tmux/wb family-decision "<short title>" <<'EOF'
status: proposed
affects: [dotfiles--family-hook, dotfiles--family-picker]
discussed in: dotfiles--coordinators
from: dotfiles--family-hook / <the worker's title>

What it is, and what it changes for each affected task.
EOF
```

`from:` must match the worker's entry exactly (`<stem> / <title>`), or the
proposal keeps showing as untaken. A cross-task item raised here directly
has no `from:` line.

If a worker recorded something as single-task that affects a sibling, raise
it with Jet here. If Jet agrees, record it as a family decision whose
`from:` points at the worker's entry.

**Confirm in this session.** Ask Jet to confirm, then rewrite the entry under
the same title with `status: in-force` and a `confirmed:` line holding the
date and Jet's reply verbatim.

**Message only to unblock.** Once a decision is in force, message each
worker whose Holding line waits on it, idle ones included: find them with
ListAgents, send with SendMessage. Say which decision is now in force and
point at `wb family`. Send no other messages to workers. Everything else
reaches them through the family view.
