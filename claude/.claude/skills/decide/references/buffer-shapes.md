# Buffer shapes

Two shapes for the `/decide` buffer. Both are plain markdown that Jet edits in
nvim and closes with `:wq`. Keep the top comment: it's the only instruction
he sees.

## Questions

For choices plus free text. Every question states its default, so a blank
answer still means something.

~~~markdown
# Decisions: <topic>
<!-- Put an x in one box per question, or write under "Other". A question
     left blank takes its default. Notes go under any question. :wq when done. -->

## 1. <Short title, used as the Decisions entry title>

<Two or three sentences of context: what hangs on it, and what you recommend.>

- [ ] A. <option> (default)
- [ ] B. <option>
- Other:
- Notes:

## 2. <Short title>

…
~~~

Keep it to about six questions. More than that, or any question that needs a
diagram, table or long evidence, belongs on a page.

## Run and paste

For a loop where Jet runs commands somewhere you can't (another machine, a
real login, a GUI) and pastes back what he sees.

~~~markdown
# Run and paste: <topic>
<!-- Run each command where it says, paste what it prints under Output.
     Skip one by writing "skip". :wq when done. -->

## 1. <What this checks>

Where: <machine or app>

```sh
<command>
```

Output:

Notes:
~~~

After reading the answers, record a decision only for what Jet decided. Use
the pasted output as evidence for the next step, not as a Decisions entry.
