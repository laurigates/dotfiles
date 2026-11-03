# Dependency Management

Tool installation priority (mise → uv → bun → cargo/go → brew) is defined
once in `~/.claude/CLAUDE.md` § Tool Installation Priority.

## Running With a Specific Version — `mise exec`, Not `mise use`

For a one-off run under a specific runtime version, use
`mise exec <tool>@<version> -- <cmd>` (e.g. `mise exec python@3.14 -- uv run script.py`).
`mise use` writes the version into the active `mise.toml` / `.tool-versions`
and silently changes the default for everything else. Reach for `mise use` only
when you want to change the default going forward.

## `uvx` Pins Itself to a Stale Build — Request `@latest`

`uvx <pkg>` does not consult the index on a normal run and its cache never
expires: an installed tool (`uv tool install`) wins, otherwise the first
resolution sticks. `--refresh`, `--reinstall` and `--refresh-package` act on the
wheel cache, not on version selection; only `@latest` and `--isolated`
re-resolve (uv 0.12.6). To tell the two apart, point `UV_TOOL_DIR` at an empty
dir and re-run — a version jump means an installed copy was shadowing the index.

**Write `uvx <pkg>@latest` in any config that must track releases** — MCP server
entries in `.mcp.json` above all. Pin `<pkg>==1.2.3` instead when
reproducibility outranks currency.

## Upgrade Patterns

- Replace deprecated tools promptly — no compatibility shims or dual-install period
- Update CI workflows alongside local tooling
- Prefer tools with native completion support over manual completion scripts
