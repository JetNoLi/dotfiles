---
name: diagram
description: Draw a diagram in the format that fits where it will be read. Hand-written SVG on a page for diagrams Jet reads; D2 for diagrams kept in a repo and for large or generated graphs. Covers designing, mapping existing code, explaining and reviewing, at system, frontend, backend or infra level. Use when Jet types /diagram or asks for a diagram, architecture picture, flow, sequence, ERD or map of a codebase or change.
---

# /diagram

Formats were chosen in a trial on real wb diagrams (task
`dotfiles--backlog-skills-research`, decision "Diagram formats per case").
Hand-written SVG reads best but costs about 4× D2's tokens and needs a check
against a render. D2 lays itself out and its source is short and diffable.
Jet doesn't want Mermaid, even where another skill suggests it.

Arguments: `` (what to draw, or nothing to ask)

## 1. Settle what it's for

Work these out from the request; ask in chat only if the answer changes the
format.

- **Case:** designing something new, mapping code that exists, explaining a
  mechanism, or reviewing a change.
- **Level:** system, frontend, backend or infra.
- **Where it lives:** a page Jet reads now, or a file kept in a repo.
- **Size:** about how many boxes. Past ~15, nobody places them well by hand.

Then draw the mechanism the question turns on, not an inventory. Label every
arrow.

## 2. Pick the format

| Situation | Format |
|---|---|
| Jet reads it on a page, up to ~15 boxes | Hand-written SVG (section 3) |
| Kept in a repo | D2 source plus its rendered SVG (section 4) |
| More than ~15 boxes, or generated from code | D2 or a generator (sections 4 and 5), embedded in the page if Jet reads it there |
| A sequence of calls | D2 `shape: sequence_diagram` in a repo; SVG lifelines on a page |
| A C4 model the repo maintains (`workspace.dsl` exists) | Structurizr (section 6) |

Say the case, level and format in one line before drawing.

## 3. Hand-written SVG on a page

1. Load `artifact-diagramming` (and `artifact-design` before writing a page).
   Follow its mechanics: `viewBox`, `currentColor`, one highlight colour,
   labelled arrows, `<figure>` with a caption.
2. Plan the grid before writing: columns and rows, each box's slot, and
   which arrows cross what. Put boxes that talk to each other next to each
   other so their arrow is short and straight.
3. Write the SVG.
4. **Check it against a render before showing it.** Copy the SVG into the
   scratchpad with a fixed colour, render it, and look:

   ```bash
   sed 's/<svg /<svg style="color:#222;background:#fff" /' in.svg > "$SCRATCH/check.svg"
   qlmanage -t -s 1400 -o "$SCRATCH" "$SCRATCH/check.svg" >/dev/null 2>&1
   ```

   Read `$SCRATCH/check.svg.png`. Fix any label sitting on a line or box,
   any arrow ending short of its box, and any text off the edge. In the trial
   the first pass had about five such collisions. Stop after two rounds; if
   it still doesn't read, the diagram has too many boxes for hand placement,
   so switch to D2.

## 4. D2

Installed via Homebrew. Write `<name>.d2`, then render:

```bash
d2 --layout elk --theme 1 --dark-theme 200 --pad 20 <name>.d2 <name>.svg
```

- Use `elk` for boxes and arrows; sequence diagrams ignore the layout.
- `--dark-theme` only switches the theme's own colours. A colour set in the
  D2 source doesn't adapt to dark mode, so highlight with `stroke-width` or
  `bold` rather than a fill.
- In a repo, commit the `.d2` and the `.svg` side by side, under the repo's
  diagram folder or `docs/diagrams/`, and link the SVG from the markdown.
  GitHub doesn't render D2 itself.
- On a page, publish the rendered SVG as a file and show it with `<img>`.
- Render and look before showing it, as in section 3, step 4. D2 can still
  put a label over a box.

## 5. Generating from code

Mapping code at scale starts from a generator, not from reading every file.
Only Graphviz is installed; anything else needs Jet's approval, and an
unknown tool goes through `/research` vetting first.

| Level | Tool | State |
|---|---|---|
| Frontend (JS/TS modules) | `npx -y dependency-cruiser@18.7.2 --include-only '^src' --output-type dot src \| dot -Tsvg > deps.svg` | Needs Node 22+ (`nvm use 22`); untried on a real repo |
| Backend schema | tbls + Liam ERD | Not installed |
| Infra (Terraform) | `terraform graph \| dot -Tsvg` | Terraform not installed |
| Python or mixed repos, and review | repo2diagram (`--diff main` for a change, `--no-llm` keeps it local) | Not installed; one-maintainer beta |

A generated graph is usually too big to read whole. Group or filter it to
the part the question is about, or redraw that part by hand.

**Reviewing a change:** start from `git diff --name-only <base>...HEAD`,
draw the touched components plus whatever depends on them, and mark the
changed ones. Before and after side by side beats one busy picture.

## 6. Structurizr

Only for a repo that keeps a C4 model. It rejects a wrong model and drops
detail it doesn't model, so it isn't for one-off diagrams. Pinned images:

```bash
docker run --rm -v "$PWD:/w" structurizr/structurizr:2026.09.19-playwright \
  export -w /w/workspace.dsl -f plantuml/c4plantuml -o /w/puml
docker run --rm -v "$PWD/puml:/w" plantuml/plantuml:1.2026.9 -tsvg -o /w/svg "/w/*.puml"
```

## Rules

- Never send diagram source or code to a hosted renderer or editor (the
  public PlantUML server, Eraser, Stately's import) without asking. Every
  tool above runs locally.
- JetNoLi/dotfiles is public: diagrams committed there carry no employer
  details.
- Mark anything proposed rather than built, in the caption or the title.
