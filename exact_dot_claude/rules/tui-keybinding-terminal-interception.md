# A TUI Keybinding That "Does Nothing" Is Often the Terminal Eating the Key

**Scope**: debugging a terminal UI (crossterm/ratatui/promkit app, or any
full-screen CLI) where a configured keybinding appears dead — the app doesn't
react and there's no error. Especially under **kitty** on macOS, but the
pattern generalizes to any terminal with its own shortcut layer.

## The trap

When a TUI key does nothing, the instinct is to debug the *app* — its keymap,
its event matching, its focus model. But the terminal sits between the keyboard
and the app and **consumes its own configured shortcuts before the program ever
sees the keystroke**. A key bound to a terminal action is silently swallowed:
no bytes reach the app, so no amount of app-side config or code can catch it.
The failure is invisible — the app behaves exactly as if the key were unbound.

> Canonical break (jnv on kitty, 2026-06): the JSON-viewer nav keys looked
> completely dead. Root cause was **not** jnv — kitty intercepted `shift+down`/
> `shift+up` (mapped to `move_window` in the user's own `kitty.conf`), so jnv's
> `switch_mode` focus-switch never fired, leaving focus stuck on the editor and
> the entire viewer keymap unreachable. Two replacement guesses *also* collided:
> `ctrl+shift+arrow` is a kitty **built-in default** (scrollback scroll). The fix
> was a key kitty forwards: bare `Ctrl+<letter>` (`switch_mode = ["Ctrl+T"]`).

## Diagnose: is the terminal or the app eating it?

Prove where the key dies before touching app code. Two kitty tools (adapt for
other terminals — most have a key-debug mode):

```sh
# 1. Does the app receive the key at all? (runs a program inside kitty)
kitty +kitten show_key -m kitty        # press the key; nothing printed = terminal ate it

# 2. Does kitty itself consume it? (logs every key + whether it matched a shortcut)
kitty --debug-keyboard                 # look for: "KeyPress matched action: <X>, handled as shortcut"
```

`handled as shortcut` (or the equivalent in your terminal's debug output) is the
smoking gun: the terminal claimed the key. If `show_key` prints a clean
`CSI ... u` / escape sequence, the key *is* reaching the app and the bug is
app-side after all.

## Commonly-intercepted combos (pick app keybinds that dodge these)

| Combo | Frequently grabbed by | Notes |
|---|---|---|
| `Shift+Arrow` | kitty `move_window` (user config), macOS text-selection (`moveDownAndModifySelection:`) | Doubly spoken-for on macOS |
| `Ctrl+Shift+Arrow` | kitty **built-in** scrollback scroll | A default, not user config — won't show in `kitty.conf` |
| `Ctrl+Arrow` | kitty `neighboring_window` / word-motion remaps | Often user-mapped |
| `Cmd+*`, `Ctrl+Shift+*` | the terminal's entire shortcut namespace | Reserve for the terminal |
| bare `Ctrl+<letter>` | **passes through** to the app (except flow-control `Ctrl+S`/`Ctrl+Q`, suspend `Ctrl+Z`) | The safe space for app keybinds |

So when an app keybind is intercepted, prefer a bare `Ctrl+<letter>` the app
doesn't already use. Confirm the terminal isn't remapping it
(`grep -niE '^\s*map\s+ctrl\+<l>' ~/.config/kitty/kitty.conf`) and the app isn't
either. Whether a `Shift+Arrow`-style combo is a terminal *default* or *user
config* matters: a user map can be changed (`map shift+down no_op`), a built-in
default usually can't without overriding it.

## Layout-impossible combos: the key can't even be typed

A third way a bind is dead — before interception even enters the picture: on
non-US layouts the **character itself needs a modifier**, so the Ctrl-combo is
unproducible. On Finnish/Nordic ISO layouts `/` is `Shift+7`, `?` is `Shift++`,
`\` is `AltGr+<`, etc. A bind like fzf's popular `ctrl-/:toggle-preview` can
never fire: the keyboard has no bare `/` key, so the terminal never emits
Ctrl+/ at all. Nothing intercepts it — it just doesn't exist. The failure is
extra-invisible because the header hint (`^/ preview`) reads as a truncated or
garbled label rather than an impossible chord.

> Canonical break (dotfiles PR #294, 2026-07): every `gh` fzf picker bound
> `ctrl-/:toggle-preview`; on a Finnish layout the preview toggle was dead in
> all of them. Fix: rebind to bare `Ctrl+T`.

The rule of thumb extends the table above: **punctuation Ctrl-combos
(`ctrl-/`, `ctrl-?`, `ctrl-\`, `ctrl-]`, `ctrl-;`…) are layout-dependent —
treat them as unavailable** when authoring binds meant to work across
keyboards. Bare `Ctrl+<letter>` is the only Ctrl-space that exists on every
layout AND passes through every terminal. Diagnosis is the same
`show_key` run: if pressing the chord prints nothing *and* the combo involves
a shifted/AltGr character on your layout, suspect the layout before the
terminal.

## Secondary, app-side: legacy key aliasing (crossterm)

Even once a key reaches the app, legacy terminal encoding aliases distinct keys
to the same byte, so a binding can be unreachable for a different reason:

- `Ctrl+J` = `0x0A` = **`Enter`** — a `Ctrl+J` binding fires `Enter` instead.
- `Ctrl+I` = `0x09` = **`Tab`**; `Ctrl+M` = `0x0D` = `Enter`.
- (`Ctrl+H` *does* decode to `Char('h')`+CONTROL in crossterm, not Backspace.)

The fix is to negotiate the **keyboard enhancement protocol** so these
disambiguate: push `KeyboardEnhancementFlags::DISAMBIGUATE_ESCAPE_CODES` when
`supports_keyboard_enhancement()` is true, pop it on teardown. **But** if the
app matches keybinds by exact `Event` equality, enabling the protocol also makes
**release/repeat events** and **`KeyEventState` lock-bits** (Caps/Num Lock)
possible — both break exact matches. Normalize incoming events at the single
read chokepoint first: drop non-`Press`, strip `KeyEventState` to `NONE`. Request
*only* `DISAMBIGUATE_ESCAPE_CODES` (not `REPORT_EVENT_TYPES`) to keep the stream
close to legacy.

## When it bites

- Any TUI on kitty/WezTerm/foot/Ghostty where a modified key (Shift/Ctrl+Arrow)
  is bound to a focus-switch, pane move, or scroll action.
- Porting a TUI's default keybinds between machines — one user's `kitty.conf`
  `map` lines silently shadow the app's keys.
- A keybind that works on one terminal and is "dead" on another — same app, the
  difference is which terminal claims the key.

## Relationship to sibling rules

- `kitty-agent-interaction.md` — the read-only kitty remote-control surface; this
  rule is the keyboard-interception debugging complement.
- `zshrc-keybindings.md` (dotfiles repo `.claude/rules/`) — the *shell*-layer analogue (zsh-vi-mode rebuilding the
  keymap after sourcing); both are "something between you and the binding ate it."

## Rationale

The instinct to debug the app is wrong half the time: the terminal's shortcut
layer is invisible in the app's config and code, so a swallowed key reads as an
app bug and sends you hunting in the wrong codebase. One `--debug-keyboard` /
`show_key` run settles *where* the key dies in seconds, converting an
open-ended app-side hunt into "the terminal grabbed it — pick a key it forwards."
