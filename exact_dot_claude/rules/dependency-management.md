# Dependency Management

Derived from git history patterns (tooling decisions across 1404 commits).
Tool installation priority (mise → uv → bun → cargo/go → brew) is defined
once in `~/.claude/CLAUDE.md` § Tool Installation Priority.

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

## `uvx` Pins Itself to a Stale Build — Request `@latest`

`uvx <pkg>` does **not** consult the index on a normal run, and the cache never
expires. Two rules hand you an old build: an installed tool wins if
`uv tool install <pkg>` ever ran, and otherwise the first resolution sticks.

The flags that look like the fix are not — `--refresh`, `--reinstall` and
`--refresh-package` act on the wheel cache, which is not what selects the
version. Only `@latest` and `--isolated` re-resolve (uv 0.12.6). To tell the
two rules apart, point `UV_TOOL_DIR` at an empty dir and re-run: if the version
jumps, an installed copy was shadowing the index.

**Write `uvx <pkg>@latest` in any config that must track releases**, MCP server
entries in `.mcp.json` above all: a bare `uvx <pkg>` pins each machine to
whatever it cached and published fixes never arrive. Pin `<pkg>==1.2.3` instead
when reproducibility outranks currency.

## Upgrade Patterns

- Replace deprecated tools promptly — don't maintain compatibility shims
- When upgrading, remove the old tool entirely (no dual-install period)
- Update CI workflows alongside local tooling
- Prefer tools with native completion support over manual completion scripts
