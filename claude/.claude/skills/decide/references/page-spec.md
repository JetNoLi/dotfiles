# Page spec

The `/decide` page (`page/page.html`) renders whatever `spec.json`, published
beside it, describes. Check a spec with `wb decide-spec-check <spec.json>`
before publishing.

## Top level

| Field | Required | Meaning |
|---|---|---|
| `title` | yes | The page heading. Also put it in the page's `<title>`. |
| `layout` | yes | `"items"`: each item has its own options. `"verdicts"`: every item takes one of a shared list. |
| `items` | yes | The questions, in order. Item ids are unique. |
| `intro` | no | One or two sentences under the title: what's being decided and why now. |
| `task` | no | The task stem, shown above the title. |
| `verdicts` | `verdicts` only | At least two `{ "id", "label" }`, such as Fix / Later / Skip. |

## An item

| Field | Required | Meaning |
|---|---|---|
| `id` | yes | Short and stable. It names the answer document, so never reuse one for a different question. |
| `title` | yes | Becomes the Decisions entry title. |
| `context` | no | Plain text. Blank lines split paragraphs, and `backticks` mark code. |
| `options` | `items` only | At least two `{ "id", "label", "detail"?, "recommended"? }`. Mark one option `recommended` when you have a view. |
| `suggested` | no, `verdicts` only | A verdict id. The row shows it as the answer until Jet picks another. |
| `blocks` | no | Evidence shown under the context, in order. See below. |

## What every item needs

Jet asks for options, their pros and cons, and a recommendation on every item.
A row with only a title gets "need more info" back.

- `items` layout: each option's `detail` says its pro and its con, and one
  option is `recommended`.
- `verdicts` layout: `context` says what the finding is, where it is, and why
  the suggested verdict, in two or three sentences. Leave `suggested` off only
  when you have no view, and then say so in the context.

## Blocks

- `{ "type": "text", "text": "…" }`: more paragraphs.
- `{ "type": "code", "text": "…" }`: a code or output block. Long lines scroll inside it.
- `{ "type": "table", "head": ["…"], "rows": [["…"]] }`: cells are plain text.
- `{ "type": "svg", "svg": "<svg …>…</svg>" }`: a diagram. Give it a `viewBox`, and use `currentColor` for strokes and text so it reads in both themes. Scripts and event handlers are stripped.

## Answers

Each answer is a document in the page's `answers` collection, keyed by item
id: `{ "choice": "<option or verdict id>", "note": "…", "updatedAt": "…" }`.
A note can come without a choice: in the `items` layout that's Jet's "Other".
Submit writes `meta/submitted`: `{ "at", "answered", "total" }`.

## Example

```json
{
  "title": "Store format",
  "layout": "items",
  "intro": "Two questions before the store work starts.",
  "items": [
    {
      "id": "fmt",
      "title": "Fixture format",
      "context": "Fixtures sit beside the tests. Markdown matches `~/tasks`.",
      "options": [
        { "id": "md", "label": "Markdown", "detail": "Same shape as real task files.", "recommended": true },
        { "id": "json", "label": "JSON", "detail": "Easy to generate, harder to read." }
      ],
      "blocks": [{ "type": "table", "head": ["Format", "Lines"], "rows": [["Markdown", "12"], ["JSON", "30"]] }]
    }
  ]
}
```
