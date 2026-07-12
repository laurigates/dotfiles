# Package & MCP Server Registries

Repo-specific registries backing package and MCP server management.
(Split out of the global `dependency-management.md` rule, which keeps the
cross-project tool-installation and `mise exec` guidance.)

## Homebrew Package Profiles

Packages are managed through `.chezmoidata/packages.toml` with profile activation in `.chezmoidata/profiles.toml`:

- `core` — Always installed
- `dev` — Development tools (default: enabled)
- `infra` — Infrastructure tools (terraform, kubectl, helm)
- `gui` — GUI applications (cask installs)
- Enable/disable profiles by toggling flags in `profiles.toml`

## MCP Server Management

- Registry of available servers in `.chezmoidata.toml` under `[mcp_servers]`
- Enable/disable per server — `enabled = true/false`
- Servers are installed per-project into that project's `.mcp.json`
- Use `/configure:mcp` to install servers into a project; `./cleanup-mcp-servers.sh` to remove them (run only when no Claude sessions are active)
