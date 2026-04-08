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

## Homebrew Package Profiles

Packages are managed through `.chezmoidata/packages.toml` with profile activation in `.chezmoidata/profiles.toml`:

- `core` — Always installed
- `dev` — Development tools (default: enabled)
- `infra` — Infrastructure tools (terraform, kubectl, helm)
- `gui` — GUI applications (cask installs)
- Enable/disable profiles by toggling flags in `profiles.toml`

## Upgrade Patterns

- Replace deprecated tools promptly — don't maintain compatibility shims
- When upgrading, remove the old tool entirely (no dual-install period)
- Update CI workflows alongside local tooling
- Prefer tools with native completion support over manual completion scripts

## MCP Server Management

- Registry of available servers in `.chezmoidata.toml` under `[mcp_servers]`
- Enable/disable per server — `enabled = true/false`
- Project-specific overrides in per-project `.mcp.json`
- Use `update-ai-tools.sh` for safe updates during active sessions
