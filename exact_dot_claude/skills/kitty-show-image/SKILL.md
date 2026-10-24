---
name: kitty-show-image
description: Show an image (screenshot, render, diagram PNG) to the user with a note saying what to judge — SendUserFile first, or a labelled kitty tab via show-image.sh when they want it in the terminal. Use when the user should look at an image, for a visual gate, or when icat fails with "open /dev/tty: device not configured".
---

# Showing an Image to the User

Claude Code cannot draw images inside the chat. Kitty's graphics protocol
needs escape codes written to a real terminal, and both the Bash tool and the
user's `!` commands run without `/dev/tty`. A plain
`kitty +kitten icat` from either fails with
`open /dev/tty: device not configured`.

## Every image goes out with a note

The user should never have to switch back to the chat to find out what they
are looking at. Whichever channel you use, send the explanation with the image:

- **What it is**: the subject, the run or commit, and what each panel shows
  when the image has several.
- **What to look at**: for several figures or regions, a table of each one and
  what it should show.
- **What is expected to look off for now**, so the user doesn't report a known
  gap.
- **For a decision**: the question and the exact answer to type back in Claude
  Code ("23 accept", or name the figure that is wrong).

For the kitty tab, write the note to a file and pass `--note`. For
`SendUserFile`, put the same text in `caption`. Send one image per question.

## Pick the channel

| Situation | Channel |
|---|---|
| Default: any image the user should see | `SendUserFile` with `display: "render"` and the note as `caption`. No terminal mutation, and the file also reaches the user's other devices. |
| The user wants it in kitty, or asked to see it "here" | `show-image.sh` (below). It opens and focuses a tab, so it needs the user's ask; one ask covers the rest of that session's images. |
| Not in kitty (`$KITTY_WINDOW_ID` unset) and the user is at this Mac | `open <file>` (Preview). |

## show-image.sh

```
~/.claude/skills/kitty-show-image/show-image.sh [--note FILE] IMAGE [IMAGE...]
```

Opens a tab titled **Claude: image viewer** with a banner saying it is
Claude Code's image viewer. Under the images it prints their file names and
then the `--note` text (see "Every image goes out with a note"), just above the
key prompt. With several images, only the last stay on screen above the note;
earlier ones scroll off the top. One key press closes the tab, after which
kitty returns focus to the previous tab. The script prints the new window id. To confirm the tab rendered,
read it without touching it: `kitty @ get-text --match id:<id>`.

| Exit | Meaning | Next step |
|---|---|---|
| 0 | Tab launched | Tell the user which tab to look at and that a key press closes it |
| 1 | Bad arguments or missing file | Fix the path |
| 2 | Not in kitty, or remote control unreachable | Fall back to `SendUserFile` |

## Don't

- **Don't send an image without its note.** A bare image makes the user switch
  back to the chat to find out what to judge.
- **Don't hand the user `! kitty +kitten icat …`.** The `!` shell has no TTY,
  so it fails the same way the Bash tool does.
- **Don't use `kitty @ launch --hold`, or `--type=overlay` without a banner.**
  `--hold` leaves an interactive shell prompt behind. An unlabelled overlay with
  a prompt looks exactly like Claude Code has exited; the user tries `fg` and
  has to discover that `ctrl+d` gets them back (2026-10-24).
- **Don't close the tab for the user.** It closes on their key press;
  `close-window` is on the destructive list in
  `~/.claude/rules/kitty-agent-interaction.md`.
