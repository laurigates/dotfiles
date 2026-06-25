---
paths:
  - "**/*.rs"
  - "**/tui/**"
  - "**/*markdown*"
---

# Rendering Markdown in a TUI With a Row-Precise Scroll Model

**Scope**: rendering GitHub-flavored (or any) markdown bodies inside a
terminal UI — `ratatui`/`crossterm` apps like `gh-board` and `eval-tui`,
or anything that pre-wraps styled lines and scrolls by *visual row*. Skip
for web/Markdown-to-HTML.

## The trap

Reaching for an off-the-shelf TUI markdown crate (`tui-markdown` is the
obvious one) looks like the cheap path, but it carries two behaviors that
quietly break a scrollable detail view:

1. **Soft breaks collapse to spaces.** `tui-markdown` follows CommonMark,
   where a *single* newline inside a paragraph is a soft break rendered as
   a space — so `"Line 0\nLine 1\nLine 2"` becomes one reflowed paragraph.
   GitHub renders body/comment newlines as `<br>` (hard breaks), so the
   crate's output **diverges from how the source actually looks on
   GitHub**.
2. **It silently breaks "one source line = one visual row."** Any TUI that
   pre-wraps to the inner width and scrolls a known number of *rows* (the
   only way to get exact, row-precise scrolling once wrapping is on — see
   `gh-board/src/tui/wrap.rs`) depends on a stable row count. Paragraph
   reflow changes the row count nondeterministically, so scroll clamps,
   "scroll to bottom", and comment-into-view math all drift. Tests that
   assert one row per source line (a common shape) fail.

A third, smaller annoyance: `tui-markdown` keeps **block** markers literal
(`## Heading`, `- item` render with the `##`/`-` intact, merely styled)
while stripping **inline** markers (`` ` ``, `*`) — an inconsistent read.

## The rule

For a scrollable TUI detail/body view, **hand-roll the renderer on
`pulldown-cmark`** rather than adopting an opinionated rendering crate:

- **Map soft *and* hard breaks to a row break** (`Event::SoftBreak |
  Event::HardBreak ⇒ new line`). This restores GitHub fidelity *and* keeps
  one source line = one visual row, so the scroll math stays exact.
- **Keep width out of the renderer.** Emit clean, un-indented styled
  `Vec<Line>`; let the caller add the body indent / comment gutter, and a
  separate wrap pass do the column wrapping. A width-free renderer is pure
  (`&str` in, lines out) and directly unit-testable — no `Rect`.
- **Strip every marker, style by role**: headings bold+underline, inline
  and fenced code tinted (code blocks behind a `│ ` gutter), lists →
  bullets/ordinals, blockquotes → `▌ ` gutter + dim italic, links → blue
  underline (drop the URL in a non-clickable view), task lists → glyphs,
  thematic breaks → a rule line.

This mirrors the established `wrap.rs`-over-`textwrap` precedent: when
fidelity and a load-bearing invariant (here, row-precise scrolling) are at
stake, a controlled ~450-line hand-roll beats fighting a crate's
assumptions, and every behavior gets a test.

## When it bites

- A `ratatui` app showing issue/PR/comment bodies, logs, or any markdown
  in a scrollable pane (gh-board's zoomed detail; eval-tui transcripts).
- Porting the same "render markdown in a box" need between TUI projects —
  the soft-break reflow is invisible until a multi-line body scrolls wrong
  or a line-per-row test fails.

## Verify

A one-shot probe settles the crate's behavior before you commit to it:

```
cargo new --quiet /tmp/md-probe && cd /tmp/md-probe && cargo add tui-markdown ratatui
# render "a\nb\nc" and print line count — 1 line (reflowed) vs 3 confirms the trap
```

## Ref

- Evidence: `laurigates/gh-board` PR #46 (`src/tui/markdown.rs`,
  `src/tui/wrap.rs`).
- `pulldown-cmark` events: <https://docs.rs/pulldown-cmark>.
