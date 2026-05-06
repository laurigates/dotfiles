# zshrc Keybindings + zsh-vi-mode

**Scope**: applies when editing `dot_zshrc.tmpl` (chezmoi source) or
`~/.zshrc` (target). Skip otherwise.

## The trap

`zsh-vi-mode` (jeffreytse/zsh-vi-mode) defers most of its keymap setup
to a ZLE pre-prompt hook that fires *after* `~/.zshrc` finishes
sourcing. That deferred init rebuilds the `main` keymap from scratch,
wiping every `bindkey ...` call and every `source <(fzf --zsh)` that
ran during `.zshrc`. Source order in `.zshrc` does not save you —
the rebuild happens after the file ends.

## Rule

When `zsh-vi-mode` is sourced in `.zshrc`, every binding that targets
`main` — i.e. any `bindkey ...` call without an explicit `-M <keymap>`
flag, plus any plugin that injects bindings into `main` at source time
(notably `source <(fzf --zsh)`) — **must live inside the
`zvm_after_init` function**, not at file top-level.

`zvm_after_init` is the documented extension hook the plugin calls
as the last step of its deferred init.

## Pattern

```zsh
# Source the plugin (registers a deferred init; bindings come later)
source ~/zsh/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# Everything that touches `main` runs after vi-mode rebuilds it
function zvm_after_init() {
  source <(fzf --zsh)                  # Ctrl+T, Ctrl+R, Alt+C
  bindkey . rationalise-dot
  bindkey '\ec' fzf-cd-widget
  bindkey -s "^[[60;9u" "|"
}
```

## What stays safe at file top-level

- `zle -N <widget>` — widget table is not rebuilt
- `bindkey -M vicmd ...`, `bindkey -M visual ...`, custom keymaps —
  vi-mode only rewrites `main`
- `ZVM_*` variable assignments — must be set *before* the plugin is
  sourced (vi-mode reads them at source time)

## Do not "fix" Ctrl+C/D/L with `bindkey -e`

If Ctrl+C/D/L feel broken, the cause is usually that `bindkey -v`
(or `EDITOR=nvim` triggering vi mode implicitly) is in effect *without*
zsh-vi-mode. Switching to `bindkey -e` works but throws away vim
motions entirely.

The right fix is to source `zsh-vi-mode`, which rebinds the common
emacs survivors (Ctrl+A/E/F/B/N/P/R/W/U/Y, Ctrl+C/D/L) inside `viins`
so insert mode behaves like emacs while `Esc` still drops into
`vicmd` for motions. Do not reintroduce `bindkey -e` as a workaround.

## Quick check before committing

```zsh
exec zsh                     # fresh shell
bindkey | grep rationalise   # custom binds present in `main`?
bindkey -M vicmd | head      # vi command mode populated?
```

If `bindkey | grep <your-bind>` returns nothing after a fresh shell,
the binding got wiped — move it into `zvm_after_init`.
