# A CLI Tool "Keeps Coming Back" in a mise Node Path

When a globally-installed CLI tool (notably `claude`, but any
`npm install -g` binary) reappears in a mise-managed runtime path even
after you "removed" it, the cause is almost never an active reinstall.
It is **stale per-version copies** scattered across the runtime versions
mise has installed. mise keeps a separate `node_modules` tree per node
version, so a global package installed under one version lives only
there — and every *other* installed version may carry its own old copy.

Removing the tool from the *active* version makes it look gone, until
mise activates a different version (a project pins `node@22`, a
`mise exec node@24 -- …`, an `.mise.toml` switch) and that version's
leftover shim resurfaces. The tool "comes back" without anything
reinstalling it.

## The trap

```sh
# Looks installed once…
which -a claude            # → ~/.local/bin/claude   (native, fine)
# …but the running process is a DIFFERENT copy:
#   "npm-global at .../mise/installs/node/22.21.1/bin/claude"
```

A single `npm uninstall -g` (or deleting one symlink) only touches the
active version. The copies under the other ~10 node version dirs stay.

## Check all three locations, not just the active one

```sh
# 1. Per-version global node_modules — the real footprint
ls -d ~/.local/share/mise/installs/node/*/lib/node_modules/@anthropic-ai/claude-code

# 2. Per-version bin symlinks
ls -la ~/.local/share/mise/installs/node/*/bin/claude

# 3. The mise shim (points back at the mise binary; survives uninstall)
ls -la ~/.local/share/mise/shims/claude

# 4. The auto-reinstall trigger: mise installs these into EVERY new
#    node version. If the tool is listed here, it genuinely will return.
cat ~/.default-npm-packages    # chezmoi source: dot_default-npm-packages
```

## Remove from every version + the shim

```sh
for d in ~/.local/share/mise/installs/node/*/lib/node_modules/@anthropic-ai; do [ -d "$d" ] && rm -rf "$d"; done
for s in ~/.local/share/mise/installs/node/*/bin/claude;  do rm -f "$s"; done
rm -f ~/.local/share/mise/shims/claude
```

Note: deleting files of the *currently running* process is safe on
macOS — the open inode persists until the process exits; the live
session keeps working and the next fresh-shell launch resolves to the
native binary.

## Make sure it stays gone

- **`~/.default-npm-packages` must NOT list the tool.** This file (mise
  reads it on every node install, like asdf/nvm) is the only mechanism
  that auto-reinstalls a global into new versions. If the tool is here,
  removing the copies is pointless — it returns on the next
  `node = "latest"` bump. Source it in chezmoi: `dot_default-npm-packages`.
- **PATH precedence**: `~/.local/bin` (native install) should resolve
  before any mise node `bin`/shim dir. `which -a claude` returning *only*
  the native path confirms it.
- For `claude` specifically, the native installer is canonical:
  `~/.claude.json` should show `"installMethod": "native"` and
  `"autoUpdates": false` so `claude update` targets the native copy, not
  an npm one.

## Rationale

The mise "global package per runtime version" model means *uninstall*
has a per-version blast radius, but *PATH activation* roams across
versions — so a one-version uninstall produces a tool that intermittently
reappears with no visible installer. The fix is to sweep every version
dir plus the shim, and to confirm `~/.default-npm-packages` isn't quietly
re-seeding it. Same pattern applies to any mise-provided runtime
(Python `pipx:` globals, bun globals): check all installed versions, not
just the active one.
