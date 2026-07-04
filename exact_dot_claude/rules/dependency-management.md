# Dependency Management

Derived from git history patterns (tooling decisions across 1404 commits).

## Tool Installation Priority

1. **mise** with appropriate backend:
   - Core runtimes: `python`, `node`, `go`, `rust`, `bun`
   - Python CLIs: `pipx:` backend (runs via uvx)
   - Standalone binaries: `aqua:` backend (checksum verification)
2. **uv tool install** — Python tools as isolated packages
3. **bun install -g** — JavaScript/TypeScript global packages
4. **cargo install** / **go install** — When not available via aqua
5. **brew install** — Last resort for CLI tools; primary for system packages and GUI apps

## Running With a Specific Version — `mise exec`, Not `mise use`

When a command needs a *specific* version of a mise-provided runtime (Python,
Node, Go, Rust, Bun, or anything else mise installs) for one invocation, run it
through `mise exec <tool>@<version> --` instead of switching the default with
`mise use`.

```
mise exec python@3.14 -- uv run script.py
mise exec node@22 -- npm ci
mise exec go@1.23 -- go build ./...
```

Why `exec` over `use`:

- **`mise use` clobbers the default.** It writes the version into the active
  `mise.toml` / `.tool-versions`, so it persists and silently changes the
  runtime for everything else relying on the current default. `mise exec`
  scopes the version to the single command and leaves the default untouched.
- **One streamlined line.** No "switch version → run → switch back" dance, and
  no risk of forgetting the revert.
- **Composes with `uv`/`npm`/etc.** Put `mise exec …@… --` in front of the
  normal command; everything after `--` runs under the pinned runtime.

Reach for `mise use` only when you genuinely want to *change* the project's or
shell's default version going forward — not for a one-off run.

## Upgrade Patterns

- Replace deprecated tools promptly — don't maintain compatibility shims
- When upgrading, remove the old tool entirely (no dual-install period)
- Update CI workflows alongside local tooling
- Prefer tools with native completion support over manual completion scripts
