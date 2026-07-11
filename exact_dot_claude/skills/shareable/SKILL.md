---
name: shareable
description: Draft bite-sized "AI as coworker" wins, experiences, and useful failures for sharing on Google Chat. Use when the user says "draft a shareable about X", "share this win", "add a shareable", "make the technical/layman/one-liner/takeaway version of X", or "format the <topic> <register> for posting". Drafts each topic in four registers (layman, technical, one-liner, takeaway), queues them in FVH/shareables.md, and hands off a clipboard-ready Google Chat message to paste.
---

# Shareable — bite-sized sharing for Google Chat

A low-friction workflow for sharing experiences, successes, and *useful
failures* with colleagues on Google Chat. The user has two spaces in mind — an
AI-use-case space ("tekoäly työkaverina", **includes non-technical
colleagues**) and a technical space — but **drafts are organized by register,
not by space**. The user routes each register to whichever space fits when they
paste.

Delivery is **draft → clipboard → the user pastes**. Posts as the user (not a
bot), no credentials, human-in-the-loop. No webhook, no deploy.

## The four registers

Every topic is drafted in up to four registers. Default to producing all four;
honor a request for a subset ("just the layman one", "make the takeaway").

| Register | What it is | Shape |
|---|---|---|
| **layman** | Lead with the human outcome. Zero unexplained jargon — a non-technical colleague must get it. | 3–6 short lines, one idea |
| **technical** | The mechanism, the how. Tool names fine. | Same brevity, mechanism-first |
| **one-liner** | A single scannable sentence — a hook. | One sentence (use `prose-distill`) |
| **takeaway** | Framed so a colleague can adopt it themselves. | "Try this: …" |

**Categories** (set per topic in the note's metadata): `experience` |
`success` | `useful-failure`. Support useful-failure explicitly across all
registers — "I tried X, it didn't work, here's what I learned" is as shareable
as a win. The user asked for failures, not just successes.

## Quality bar

Cold-read topic, two registers, to calibrate tone:

> **layman** — 💡 A small habit that's quietly improved everything I send
> "outward" (bug reports, docs, messages): before it goes out, I have a
> *separate, fresh* AI read it with zero background — like handing it to a
> brand-new colleague. If it confuses them, it'll confuse real readers too.
> Catches the "obvious-to-me, baffling-to-everyone-else" trap before it ships.
>
> **one-liner** — I let a second, context-free AI "cold read" anything I send
> outward — if a fresh reader is confused, so will real ones be.

## Workflow

### 1. Draft (intent: "draft a shareable about X", "add a shareable")

1. **Source the topic in fact.** Read the relevant repo's `README.md` /
   `CLAUDE.md` / `.claude/rules/`, or the relevant LakuVault note, before
   writing. Ground every claim — these go to real colleagues.
2. **Draft the requested registers** (default: all four). Keep each tight per
   the table above. For the one-liner, lean on `prose-plugin:prose-distill`.
3. **Append to the queue** as a new H2 topic section in
   `~/Documents/LakuVault/FVH/shareables.md`, following the exact shape below.
   New registers start `[ ]` (pending). The note's header comment documents the
   conventions — match it.

Topic section shape:

```
## <Topic title>
- category: experience | success | useful-failure
- source: <repo path or note>

### [ ] layman
​```text
<layman message>
​```

### [ ] technical
​```text
<technical message>
​```

### [ ] one-liner
​```text
<one-sentence hook>
​```

### [ ] takeaway
​```text
<try-this tip>
​```
---
```

Author the `text` bodies in **light markdown** (`**bold**`, `-` bullets) — the
conversion to Google Chat syntax happens on the way out, not in the note.

### 2. Hand off for posting (intent: "format the cold-read takeaway for posting")

Run the bundled helper — it extracts the block, converts it via
`google-chat-format`, copies it to the clipboard, and prints it for review:

```
~/.claude/skills/shareable/format-draft.sh <register> "<topic substring>"
```

`<register>` is one of `layman|technical|one-liner|takeaway`. With no topic
substring it grabs the first **pending** block for that register. Tell the user
it's on the clipboard and ready to paste into whichever space they choose.

The user can also do this without the skill via the LakuVault justfile:
`just share-next <register>` (first pending) and `just share-list` (status
overview).

### 3. Mark posted (after the user confirms)

Only after the user says it's posted, flip that register's checkbox
`[ ]` → `[x]` in `shareables.md` (edit just the one `### [ ] <register>` line
for that topic). Never auto-mark — an unposted draft must stay `[ ]`. Registers
post independently, so flip only the one that went out.

## Defer to

- **`communication-plugin:google-chat-formatting`** — the Google Chat syntax
  rules (single-`*` bold, `•` bullets, no `#` headers). The helper shells out
  to `~/.local/bin/google-chat-format`, which implements them; don't reformat
  by hand.
- **`prose-plugin:prose-distill`** — for tightening drafts, especially the
  one-liner.

## Files

- Queue note: `~/Documents/LakuVault/FVH/shareables.md` (versioned for free by
  the vault's `vault-autocommit` LaunchAgent, every 10 min).
- Helper: `~/.claude/skills/shareable/format-draft.sh`.
