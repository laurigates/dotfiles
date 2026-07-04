# A CLI Tool "Keeps Coming Back" in a mise Node Path

mise keeps a separate global `node_modules` per node version, so an
`npm install -g` binary (notably `claude`) lives per-version: uninstalling it
from the *active* version leaves stale copies under every other installed
version, and the tool "returns" whenever mise activates one of them. No
reinstall is happening — it's leftovers.

**Sweep all three locations, not just the active version:**

```sh
ls -d ~/.local/share/mise/installs/node/*/lib/node_modules/@anthropic-ai/claude-code
ls -la ~/.local/share/mise/installs/node/*/bin/claude ~/.local/share/mise/shims/claude
for d in ~/.local/share/mise/installs/node/*/lib/node_modules/@anthropic-ai; do [ -d "$d" ] && rm -rf "$d"; done
for s in ~/.local/share/mise/installs/node/*/bin/claude; do rm -f "$s"; done
rm -f ~/.local/share/mise/shims/claude
```

**Keep it gone:** `~/.default-npm-packages` (chezmoi source
`dot_default-npm-packages`) is auto-installed into every *new* node version —
if the tool is listed there, removal is pointless. Confirm `which -a claude`
resolves only to the native `~/.local/bin/claude`, and `~/.claude.json` shows
`"installMethod": "native"`. Deleting a running process's files is safe on
macOS (open inode persists until exit).

Same pattern for any mise runtime's globals (pipx, bun): check every
installed version, not just the active one.
